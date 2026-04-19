import Foundation
import SwiftData

enum WebhookEvent: String, CaseIterable, Identifiable, Codable {
    case subscriptionAdded = "subscription.added"
    case subscriptionUpdated = "subscription.updated"
    case subscriptionDeleted = "subscription.deleted"
    case billUpcoming = "bill.upcoming"
    case trialExpiring = "trial.expiring"
    case priceChanged = "subscription.price_changed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .subscriptionAdded: return "新增订阅"
        case .subscriptionUpdated: return "编辑订阅"
        case .subscriptionDeleted: return "删除订阅"
        case .billUpcoming: return "扣款临近"
        case .trialExpiring: return "试用即将结束"
        case .priceChanged: return "价格变动"
        }
    }

    var brief: String {
        switch self {
        case .subscriptionAdded: return "添加新订阅时立即触发"
        case .subscriptionUpdated: return "编辑保存时触发"
        case .subscriptionDeleted: return "删除时触发"
        case .billUpcoming: return "到期前 N 天扫描时触发"
        case .trialExpiring: return "试用结束前 2 天与当日触发"
        case .priceChanged: return "当价格变化时立即触发"
        }
    }
}

enum WebhookHTTPMethod: String, CaseIterable, Identifiable, Codable {
    case post = "POST"
    case put = "PUT"
    case get = "GET"
    var id: String { rawValue }
}

@Model
final class WebhookEndpoint {
    var stableID: String = UUID().uuidString
    var name: String = ""
    var url: String = ""
    var enabled: Bool = true
    var secretText: String = ""
    var subscribedEventsRaw: String = WebhookEvent.allCases.map(\.rawValue).joined(separator: ",")
    var createdAt: Date = Date()

    // Custom request shape
    var useCustomBody: Bool = false
    var bodyTemplate: String = ""
    var contentType: String = "application/json; charset=utf-8"
    var httpMethodRaw: String = WebhookHTTPMethod.post.rawValue
    /// Newline-separated `Key: Value` pairs.
    var customHeadersRaw: String = ""

    var lastAttemptAt: Date? = nil
    var lastStatusCode: Int = 0
    var lastErrorMessage: String = ""
    var successCount: Int = 0
    var failureCount: Int = 0

    init(name: String, url: String, secretText: String = "", events: Set<WebhookEvent> = Set(WebhookEvent.allCases)) {
        self.name = name
        self.url = url
        self.secretText = secretText
        self.subscribedEventsRaw = events.map(\.rawValue).sorted().joined(separator: ",")
        self.createdAt = Date()
        self.stableID = UUID().uuidString
    }

    var httpMethod: WebhookHTTPMethod {
        get { WebhookHTTPMethod(rawValue: httpMethodRaw) ?? .post }
        set { httpMethodRaw = newValue.rawValue }
    }

    /// Parse `customHeadersRaw` into a dict, ignoring blank lines.
    var customHeaders: [(String, String)] {
        customHeadersRaw
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> (String, String)? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard let colon = trimmed.firstIndex(of: ":") else { return nil }
                let key = trimmed[..<colon].trimmingCharacters(in: .whitespaces)
                let val = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { return nil }
                return (key, val)
            }
    }

    var subscribedEvents: Set<WebhookEvent> {
        get {
            let parts = subscribedEventsRaw.split(separator: ",").map(String.init)
            return Set(parts.compactMap { WebhookEvent(rawValue: $0) })
        }
        set {
            subscribedEventsRaw = newValue.map(\.rawValue).sorted().joined(separator: ",")
        }
    }

    func subscribes(to event: WebhookEvent) -> Bool {
        subscribedEvents.contains(event)
    }

    var lastStatusText: String {
        guard lastAttemptAt != nil else { return "未发送" }
        if !lastErrorMessage.isEmpty { return "失败 · \(lastErrorMessage)" }
        if (200..<300).contains(lastStatusCode) { return "成功 · HTTP \(lastStatusCode)" }
        return "HTTP \(lastStatusCode)"
    }
}
