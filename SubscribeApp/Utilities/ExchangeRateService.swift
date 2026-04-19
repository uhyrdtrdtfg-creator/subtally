import Foundation

extension Notification.Name {
    static let exchangeRateDidUpdate = Notification.Name("ExchangeRateDidUpdate")
}

@MainActor
final class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()

    @Published private(set) var lastFetched: Date?
    @Published private(set) var lastSource: String = "static"

    private enum Key {
        static let rate = "shared.usdCnyRate"
        static let lastFetched = "shared.usdCnyRate.lastFetched"
        static let source = "shared.usdCnyRate.source"
    }

    private static let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!
    private static let sourceLabel = "open.er-api"

    private var inflight: Task<Void, Never>?

    private init() {
        let defaults = AppGroup.sharedDefaults
        let ts = defaults.double(forKey: Key.lastFetched)
        if ts > 0 {
            self.lastFetched = Date(timeIntervalSince1970: ts)
        }
        if let src = defaults.string(forKey: Key.source), !src.isEmpty {
            self.lastSource = src
        }
    }

    func refreshIfStale(maxAge: TimeInterval = 6 * 3600) async {
        if let last = lastFetched, Date().timeIntervalSince(last) < maxAge {
            return
        }
        await refresh()
    }

    func refresh() async {
        if let inflight {
            await inflight.value
            return
        }
        let task = Task { await performRefresh() }
        inflight = task
        await task.value
        inflight = nil
    }

    private func performRefresh() async {
        var request = URLRequest(url: Self.endpoint)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            // 解析后写入完整汇率字典，覆盖约 150 种货币
            let decoded = try JSONDecoder().decode(Resp.self, from: data)
            guard !decoded.rates.isEmpty else {
                return
            }
            let now = Date()
            // 写入完整汇率字典（同时兼容旧的 usdCnyRate 键）
            AppGroup.writeAllRates(decoded.rates)

            // 维护现有的 lastFetched / source 元数据
            let defaults = AppGroup.sharedDefaults
            defaults.set(now.timeIntervalSince1970, forKey: Key.lastFetched)
            defaults.set(Self.sourceLabel, forKey: Key.source)

            self.lastFetched = now
            self.lastSource = Self.sourceLabel

            NotificationCenter.default.post(name: .exchangeRateDidUpdate, object: nil)
        } catch {
            // 网络或解码失败：保留已有缓存值
            return
        }
    }

    // open.er-api 返回的最小可解析结构
    private struct Resp: Decodable {
        let rates: [String: Double]
        let result: String?
    }
}
