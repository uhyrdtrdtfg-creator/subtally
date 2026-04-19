import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.samxiao.SubscribeApp"

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    static var storeURL: URL {
        containerURL.appendingPathComponent("Subscribe.sqlite")
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    enum SharedKey {
        static let usdCnyRate = "shared.usdCnyRate"
        static let displayCurrency = "shared.displayCurrency"
    }

    static var usdCnyRate: Double {
        let v = sharedDefaults.double(forKey: SharedKey.usdCnyRate)
        return v > 0 ? v : 7.25
    }

    static var displayCurrency: CurrencyCode {
        guard let raw = sharedDefaults.string(forKey: SharedKey.displayCurrency),
              let c = CurrencyCode(rawValue: raw) else { return .cny }
        return c
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Subscription.self, WebhookEndpoint.self, PriceChange.self])
        let sharedURL = storeURL

        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil,
           FileManager.default.ubiquityIdentityToken != nil {
            let config = ModelConfiguration(
                schema: schema,
                url: sharedURL,
                cloudKitDatabase: .private("iCloud.com.samxiao.SubscribeApp")
            )
            if let c = try? ModelContainer(for: schema, configurations: [config]) {
                return c
            }
        }
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil {
            let config = ModelConfiguration(
                schema: schema,
                url: sharedURL,
                cloudKitDatabase: .none
            )
            if let c = try? ModelContainer(for: schema, configurations: [config]) {
                return c
            }
        }
        let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: [fallback])
    }
}

// MARK: - 多币种汇率缓存与换算
extension AppGroup {
    // 多币种缓存使用的 UserDefaults 键
    enum RatesKey {
        static let allRatesJSON = "shared.allRatesJSON"
        static let allRatesFetchedAt = "shared.allRatesFetchedAt"
    }

    /// 所有汇率均以 1 USD 为基准，例如 ["CNY": 7.21, "EUR": 0.92, "NGN": 1500, ...]
    /// 缓存为空时回退到内置默认值，保证离线场景仍能换算
    static var allRates: [String: Double] {
        if let data = sharedDefaults.data(forKey: RatesKey.allRatesJSON),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data),
           !dict.isEmpty {
            return dict
        }
        return fallbackRates
    }

    /// 写入完整汇率字典到 App Group 共享存储，并同步更新 usdCnyRate 以兼容旧调用点
    static func writeAllRates(_ rates: [String: Double]) {
        if let data = try? JSONEncoder().encode(rates) {
            sharedDefaults.set(data, forKey: RatesKey.allRatesJSON)
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: RatesKey.allRatesFetchedAt)
        }
        // 兼容性写入：保持 usdCnyRate 旧键可用
        if let cny = rates["CNY"], cny > 0 {
            sharedDefaults.set(cny, forKey: SharedKey.usdCnyRate)
        }
    }

    /// 通过 USD 作为枢轴在两种 ISO 货币代码之间换算 amount
    /// 任一货币缺失时返回原值，避免在数据不完整时产生 0
    static func convert(_ amount: Double, from: String, to: String, rates: [String: Double]? = nil) -> Double {
        if from == to { return amount }
        let r = rates ?? allRates
        let fromRate = from == "USD" ? 1.0 : (r[from] ?? 0)
        let toRate = to == "USD" ? 1.0 : (r[to] ?? 0)
        guard fromRate > 0, toRate > 0 else { return amount }
        let usd = amount / fromRate
        return usd * toRate
    }

    /// 内置默认汇率：首次启动或离线时使用，覆盖常见的全球货币
    static let fallbackRates: [String: Double] = [
        "USD": 1.0, "CNY": 7.25, "EUR": 0.92, "GBP": 0.79, "JPY": 156.0,
        "KRW": 1370.0, "HKD": 7.83, "TWD": 32.0, "AUD": 1.52, "CAD": 1.37,
        "NZD": 1.66, "SGD": 1.34, "CHF": 0.91, "SEK": 10.7, "NOK": 10.7,
        "DKK": 6.85, "INR": 83.0, "RUB": 91.0,
        "NGN": 1500.0, "KES": 130.0, "ZAR": 18.5, "EGP": 47.5, "GHS": 15.5,
        "ETB": 56.0, "TZS": 2700.0, "UGX": 3700.0, "MAD": 9.95, "DZD": 134.0,
        "XOF": 605.0, "XAF": 605.0, "RWF": 1320.0, "ZMW": 26.0, "MUR": 46.0,
        "BWP": 13.6, "NAD": 18.5, "AOA": 870.0, "TND": 3.13, "MWK": 1750.0,
        "SAR": 3.75, "AED": 3.67, "QAR": 3.64, "KWD": 0.31, "ILS": 3.7,
        "TRY": 35.0, "PKR": 280.0, "BDT": 110.0, "LKR": 300.0, "NPR": 133.0,
        "THB": 35.5, "MYR": 4.55, "IDR": 16000.0, "PHP": 57.0, "VND": 25000.0,
        "BRL": 5.6, "MXN": 17.0, "ARS": 1000.0, "PLN": 4.0, "CZK": 23.0,
        "HUF": 360.0, "UAH": 41.0,
    ]
}
