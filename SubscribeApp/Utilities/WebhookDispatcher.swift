import Foundation
import SwiftData
import CryptoKit

@MainActor
final class WebhookDispatcher {
    static let shared = WebhookDispatcher()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    /// Fire an event for a single subscription against all matching enabled endpoints.
    func fire(event: WebhookEvent, sub: Subscription, context: ModelContext, usdCnyRate: Double) async {
        // NOTE: avoid `#Predicate` on Bool — SwiftData on iOS 17 has a known runtime
        // trap (EXC_BREAKPOINT) when evaluating Bool predicates with default values.
        // Fetch all and filter in-memory; cardinality is small (typically <10 endpoints).
        let descriptor = FetchDescriptor<WebhookEndpoint>()
        guard let all = try? context.fetch(descriptor), !all.isEmpty else { return }
        let targets = all.filter { $0.enabled && $0.subscribes(to: event) }
        guard !targets.isEmpty else { return }

        // Render bodies on the main actor first so we don't need to hop in tasks.
        let prepared: [(WebhookEndpoint, Data)] = targets.map { endpoint in
            (endpoint, buildBody(for: endpoint, event: event, sub: sub, usdCnyRate: usdCnyRate, context: context))
        }

        await withTaskGroup(of: Void.self) { group in
            for (endpoint, body) in prepared {
                group.addTask { [weak self] in
                    await self?.deliver(body: body, event: event, endpoint: endpoint, context: context)
                }
            }
        }
    }

    private func buildBody(for endpoint: WebhookEndpoint, event: WebhookEvent, sub: Subscription, usdCnyRate: Double, context: ModelContext? = nil) -> Data {
        if endpoint.useCustomBody && !endpoint.bodyTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let previousPrice: Double? = {
                guard event == .priceChanged, let ctx = context else { return nil }
                return PriceChangeRecorder.recent(for: sub.stableID, limit: 1, context: ctx).first?.oldPrice
            }()
            let vars = WebhookTemplate.variables(
                event: event, sub: sub,
                timestamp: Date(), deliveryID: UUID().uuidString,
                usdCnyRate: usdCnyRate,
                previousPrice: previousPrice
            )
            let rendered = WebhookTemplate.render(endpoint.bodyTemplate, vars: vars)
            return rendered.data(using: .utf8) ?? Data()
        }
        let payload = WebhookPayload(event: event, sub: sub, usdCnyRate: usdCnyRate)
        return (try? WebhookEncoder.shared.encode(payload)) ?? Data()
    }

    /// Send a test payload to a specific endpoint, returns user-friendly result.
    func sendTest(endpoint: WebhookEndpoint, context: ModelContext, usdCnyRate: Double) async -> String {
        let dummy = Subscription(
            name: "Test Subscription",
            category: .ai,
            price: 9.99,
            currency: .usd,
            cycle: .month,
            nextBillingDate: Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            slug: "openai",
            brandColorHex: "10A37F",
            fallbackLetter: "T"
        )
        let body = buildBody(for: endpoint, event: .subscriptionAdded, sub: dummy, usdCnyRate: usdCnyRate)
        return await deliverOnce(body: body, event: .subscriptionAdded, endpoint: endpoint, context: context, isTest: true)
    }

    /// Render a preview body without sending. Used by EditView to show what will be POSTed.
    func renderPreview(for endpoint: WebhookEndpoint, usdCnyRate: Double) -> String {
        let dummy = Subscription(
            name: "Netflix", category: .video, price: 68, currency: .cny, cycle: .month,
            nextBillingDate: Calendar(identifier: .gregorian).date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            slug: "netflix", brandColorHex: "E50914", fallbackLetter: "N"
        )
        let body = buildBody(for: endpoint, event: .billUpcoming, sub: dummy, usdCnyRate: usdCnyRate)
        return String(data: body, encoding: .utf8) ?? ""
    }

    private func deliver(body: Data, event: WebhookEvent, endpoint: WebhookEndpoint, context: ModelContext) async {
        let attempts = [0.0, 1.0, 4.0]
        for (i, delay) in attempts.enumerated() {
            if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
            let result = await singleAttempt(body: body, event: event, endpoint: endpoint)
            if result.ok {
                update(endpoint: endpoint, success: true, status: result.status, error: "", context: context)
                return
            }
            if i == attempts.count - 1 {
                update(endpoint: endpoint, success: false, status: result.status, error: result.errorMessage, context: context)
            }
        }
    }

    @discardableResult
    private func deliverOnce(body: Data, event: WebhookEvent, endpoint: WebhookEndpoint, context: ModelContext, isTest: Bool) async -> String {
        let result = await singleAttempt(body: body, event: event, endpoint: endpoint)
        update(endpoint: endpoint, success: result.ok, status: result.status, error: result.errorMessage, context: context)
        if result.ok { return "成功 · HTTP \(result.status)" }
        if !result.errorMessage.isEmpty { return "失败 · \(result.errorMessage)" }
        return "失败 · HTTP \(result.status)"
    }

    private struct Attempt {
        let ok: Bool
        let status: Int
        let errorMessage: String
    }

    private func singleAttempt(body: Data, event: WebhookEvent, endpoint: WebhookEndpoint) async -> Attempt {
        guard let url = URL(string: endpoint.url), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            return Attempt(ok: false, status: 0, errorMessage: "URL 无效")
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.httpMethod.rawValue
        if endpoint.httpMethod != .get {
            req.httpBody = body
            req.setValue(endpoint.contentType.isEmpty ? "application/json; charset=utf-8" : endpoint.contentType,
                         forHTTPHeaderField: "Content-Type")
        }
        req.setValue("Subtally-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.setValue(event.rawValue, forHTTPHeaderField: "X-Webhook-Event")
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Webhook-Delivery")

        for (k, v) in endpoint.customHeaders {
            req.setValue(v, forHTTPHeaderField: k)
        }

        if !endpoint.secretText.isEmpty,
           let secretData = endpoint.secretText.data(using: .utf8) {
            let key = SymmetricKey(data: secretData)
            let mac = HMAC<SHA256>.authenticationCode(for: body, using: key)
            let hex = mac.map { String(format: "%02x", $0) }.joined()
            req.setValue("sha256=\(hex)", forHTTPHeaderField: "X-Webhook-Signature")
        }

        do {
            let (_, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                return Attempt(ok: false, status: 0, errorMessage: "无 HTTP 响应")
            }
            let ok = (200..<300).contains(http.statusCode)
            return Attempt(ok: ok, status: http.statusCode, errorMessage: ok ? "" : "")
        } catch {
            return Attempt(ok: false, status: 0, errorMessage: error.localizedDescription)
        }
    }

    private func update(endpoint: WebhookEndpoint, success: Bool, status: Int, error: String, context: ModelContext) {
        endpoint.lastAttemptAt = Date()
        endpoint.lastStatusCode = status
        endpoint.lastErrorMessage = error
        if success { endpoint.successCount += 1 } else { endpoint.failureCount += 1 }
        try? context.save()
    }
}
