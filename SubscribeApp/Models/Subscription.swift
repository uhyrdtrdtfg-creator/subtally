import Foundation
import SwiftData

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    case video = "VIDEO"
    case music = "MUSIC"
    case cloud = "CLOUD"
    case ai = "AI"
    case work = "WORK"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .video: return "视频"
        case .music: return "音乐"
        case .cloud: return "云存储"
        case .ai: return "AI 工具"
        case .work: return "工作"
        }
    }
}

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case usd = "USD", cny = "CNY", eur = "EUR", gbp = "GBP", jpy = "JPY"
    case krw = "KRW", hkd = "HKD", twd = "TWD", aud = "AUD", cad = "CAD"
    case nzd = "NZD", sgd = "SGD", chf = "CHF", sek = "SEK", nok = "NOK"
    case dkk = "DKK", inr = "INR", rub = "RUB"
    // 非洲
    case ngn = "NGN", kes = "KES", zar = "ZAR", egp = "EGP", ghs = "GHS"
    case etb = "ETB", tzs = "TZS", ugx = "UGX", mad = "MAD", dzd = "DZD"
    case xof = "XOF", xaf = "XAF", rwf = "RWF", zmw = "ZMW", mur = "MUR"
    case bwp = "BWP", nad = "NAD", aoa = "AOA", tnd = "TND", mwk = "MWK"
    // 其他
    case sar = "SAR", aed = "AED", qar = "QAR", kwd = "KWD", ils = "ILS"
    case `try` = "TRY", pkr = "PKR", bdt = "BDT", lkr = "LKR", npr = "NPR"
    case thb = "THB", myr = "MYR", idr = "IDR", php = "PHP", vnd = "VND"
    case brl = "BRL", mxn = "MXN", ars = "ARS", pln = "PLN", czk = "CZK"
    case huf = "HUF", uah = "UAH"

    var id: String { rawValue }

    var symbol: String { Self.meta[rawValue]?.symbol ?? rawValue }
    var displayName: String { Self.meta[rawValue]?.displayName ?? rawValue }
    var region: CurrencyRegion { Self.meta[rawValue]?.region ?? .other }

    private struct Meta { let symbol: String; let displayName: String; let region: CurrencyRegion }
    private static let meta: [String: Meta] = [
        // 主流
        "USD": .init(symbol: "$",     displayName: "美元",         region: .mainstream),
        "CNY": .init(symbol: "¥",     displayName: "人民币",       region: .mainstream),
        "EUR": .init(symbol: "€",     displayName: "欧元",         region: .mainstream),
        "GBP": .init(symbol: "£",     displayName: "英镑",         region: .mainstream),
        "JPY": .init(symbol: "¥",     displayName: "日元",         region: .mainstream),
        "KRW": .init(symbol: "₩",     displayName: "韩元",         region: .mainstream),
        "HKD": .init(symbol: "HK$",   displayName: "港币",         region: .mainstream),
        "TWD": .init(symbol: "NT$",   displayName: "新台币",       region: .mainstream),
        "AUD": .init(symbol: "A$",    displayName: "澳元",         region: .mainstream),
        "CAD": .init(symbol: "C$",    displayName: "加元",         region: .mainstream),
        "NZD": .init(symbol: "NZ$",   displayName: "新西兰元",     region: .mainstream),
        "SGD": .init(symbol: "S$",    displayName: "新加坡元",     region: .mainstream),
        "CHF": .init(symbol: "Fr",    displayName: "瑞士法郎",     region: .mainstream),
        "SEK": .init(symbol: "kr",    displayName: "瑞典克朗",     region: .mainstream),
        "NOK": .init(symbol: "kr",    displayName: "挪威克朗",     region: .mainstream),
        "DKK": .init(symbol: "kr",    displayName: "丹麦克朗",     region: .mainstream),
        "INR": .init(symbol: "₹",     displayName: "印度卢比",     region: .mainstream),
        "RUB": .init(symbol: "₽",     displayName: "俄罗斯卢布",   region: .mainstream),
        // 非洲
        "NGN": .init(symbol: "₦",     displayName: "尼日利亚奈拉", region: .africa),
        "KES": .init(symbol: "KSh",   displayName: "肯尼亚先令",   region: .africa),
        "ZAR": .init(symbol: "R",     displayName: "南非兰特",     region: .africa),
        "EGP": .init(symbol: "E£",    displayName: "埃及镑",       region: .africa),
        "GHS": .init(symbol: "₵",     displayName: "加纳塞地",     region: .africa),
        "ETB": .init(symbol: "Br",    displayName: "埃塞俄比亚比尔", region: .africa),
        "TZS": .init(symbol: "TSh",   displayName: "坦桑尼亚先令", region: .africa),
        "UGX": .init(symbol: "USh",   displayName: "乌干达先令",   region: .africa),
        "MAD": .init(symbol: "DH",    displayName: "摩洛哥迪拉姆", region: .africa),
        "DZD": .init(symbol: "DA",    displayName: "阿尔及利亚第纳尔", region: .africa),
        "XOF": .init(symbol: "CFA",   displayName: "西非法郎",     region: .africa),
        "XAF": .init(symbol: "FCFA",  displayName: "中非法郎",     region: .africa),
        "RWF": .init(symbol: "RF",    displayName: "卢旺达法郎",   region: .africa),
        "ZMW": .init(symbol: "ZK",    displayName: "赞比亚克瓦查", region: .africa),
        "MUR": .init(symbol: "₨",     displayName: "毛里求斯卢比", region: .africa),
        "BWP": .init(symbol: "P",     displayName: "博茨瓦纳普拉", region: .africa),
        "NAD": .init(symbol: "N$",    displayName: "纳米比亚元",   region: .africa),
        "AOA": .init(symbol: "Kz",    displayName: "安哥拉宽扎",   region: .africa),
        "TND": .init(symbol: "DT",    displayName: "突尼斯第纳尔", region: .africa),
        "MWK": .init(symbol: "MK",    displayName: "马拉维克瓦查", region: .africa),
        // 其他
        "SAR": .init(symbol: "﷼",     displayName: "沙特里亚尔",   region: .other),
        "AED": .init(symbol: "د.إ",   displayName: "阿联酋迪拉姆", region: .other),
        "QAR": .init(symbol: "﷼",     displayName: "卡塔尔里亚尔", region: .other),
        "KWD": .init(symbol: "KD",    displayName: "科威特第纳尔", region: .other),
        "ILS": .init(symbol: "₪",     displayName: "以色列新谢克尔", region: .other),
        "TRY": .init(symbol: "₺",     displayName: "土耳其里拉",   region: .other),
        "PKR": .init(symbol: "₨",     displayName: "巴基斯坦卢比", region: .other),
        "BDT": .init(symbol: "৳",     displayName: "孟加拉塔卡",   region: .other),
        "LKR": .init(symbol: "₨",     displayName: "斯里兰卡卢比", region: .other),
        "NPR": .init(symbol: "₨",     displayName: "尼泊尔卢比",   region: .other),
        "THB": .init(symbol: "฿",     displayName: "泰铢",         region: .other),
        "MYR": .init(symbol: "RM",    displayName: "马来西亚林吉特", region: .other),
        "IDR": .init(symbol: "Rp",    displayName: "印尼盾",       region: .other),
        "PHP": .init(symbol: "₱",     displayName: "菲律宾比索",   region: .other),
        "VND": .init(symbol: "₫",     displayName: "越南盾",       region: .other),
        "BRL": .init(symbol: "R$",    displayName: "巴西雷亚尔",   region: .other),
        "MXN": .init(symbol: "Mex$",  displayName: "墨西哥比索",   region: .other),
        "ARS": .init(symbol: "AR$",   displayName: "阿根廷比索",   region: .other),
        "PLN": .init(symbol: "zł",    displayName: "波兰兹罗提",   region: .other),
        "CZK": .init(symbol: "Kč",    displayName: "捷克克朗",     region: .other),
        "HUF": .init(symbol: "Ft",    displayName: "匈牙利福林",   region: .other),
        "UAH": .init(symbol: "₴",     displayName: "乌克兰格里夫纳", region: .other)
    ]
}

enum CurrencyRegion: String, CaseIterable {
    case mainstream  // 主流
    case africa      // 非洲
    case other       // 其他

    var displayName: String {
        switch self {
        case .mainstream: return "主流"
        case .africa: return "非洲"
        case .other: return "其他"
        }
    }
}

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case month
    case year

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .month: return "按月"
        case .year: return "年度"
        }
    }
}

@Model
final class Subscription {
    var name: String = ""
    var categoryRaw: String = SubscriptionCategory.work.rawValue
    var price: Double = 0
    var currencyRaw: String = CurrencyCode.cny.rawValue
    var cycleRaw: String = BillingCycle.month.rawValue
    var nextBillingDate: Date = Date()
    var slug: String = ""
    var brandColorHex: String = "888888"
    var fallbackLetter: String = "•"
    var createdAt: Date = Date()
    var notes: String = ""
    var isFreeTrial: Bool = false
    var trialEndDate: Date? = nil
    var totalShares: Int = 1
    var mineShares: Int = 1
    var sharedNote: String = ""
    var stableID: String = UUID().uuidString

    init(
        name: String,
        category: SubscriptionCategory,
        price: Double,
        currency: CurrencyCode,
        cycle: BillingCycle,
        nextBillingDate: Date,
        slug: String,
        brandColorHex: String,
        fallbackLetter: String,
        notes: String = "",
        isFreeTrial: Bool = false,
        trialEndDate: Date? = nil,
        totalShares: Int = 1,
        mineShares: Int = 1,
        sharedNote: String = ""
    ) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.price = price
        self.currencyRaw = currency.rawValue
        self.cycleRaw = cycle.rawValue
        self.nextBillingDate = nextBillingDate
        self.slug = slug
        self.brandColorHex = brandColorHex
        self.fallbackLetter = fallbackLetter
        self.createdAt = Date()
        self.notes = notes
        self.isFreeTrial = isFreeTrial
        self.trialEndDate = trialEndDate
        self.totalShares = totalShares
        self.mineShares = mineShares
        self.sharedNote = sharedNote
        self.stableID = UUID().uuidString
    }

    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRaw) ?? .work }
        set { categoryRaw = newValue.rawValue }
    }

    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .cny }
        set { currencyRaw = newValue.rawValue }
    }

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRaw) ?? .month }
        set { cycleRaw = newValue.rawValue }
    }
}

extension Subscription {
    func priceInCNY(usdRate: Double) -> Double {
        currency == .usd ? price * usdRate : price
    }

    func monthlyCostCNY(usdRate: Double) -> Double {
        let cny = priceInCNY(usdRate: usdRate)
        return cycle == .year ? cny / 12.0 : cny
    }

    func daysUntilNext(from today: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let a = calendar.startOfDay(for: today)
        let b = calendar.startOfDay(for: nextBillingDate)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    func daysUntilTrialEnd(from today: Date = Date()) -> Int? {
        guard isFreeTrial, let end = trialEndDate else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let a = calendar.startOfDay(for: today)
        let b = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: a, to: b).day
    }

    var isShared: Bool { totalShares > 1 }

    var shareFraction: Double {
        totalShares <= 0 ? 1.0 : Double(max(0, min(mineShares, totalShares))) / Double(totalShares)
    }

    func minePriceInCNY(usdRate: Double) -> Double {
        priceInCNY(usdRate: usdRate) * shareFraction
    }

    func mineMonthlyCostCNY(usdRate: Double) -> Double {
        monthlyCostCNY(usdRate: usdRate) * shareFraction
    }

    // MARK: - 多币种换算（基于完整汇率字典）

    /// 使用传入的汇率字典将订阅价格换算到任意目标货币
    func priceConverted(to target: CurrencyCode, rates: [String: Double]) -> Double {
        AppGroup.convert(price, from: currencyRaw, to: target.rawValue, rates: rates)
    }

    /// 月度均摊成本换算到目标货币：按年订阅自动除以 12
    func monthlyCostConverted(to target: CurrencyCode, rates: [String: Double]) -> Double {
        let p = priceConverted(to: target, rates: rates)
        return cycle == .year ? p / 12.0 : p
    }

    /// 仅自己分摊部分的月度成本，按 shareFraction 比例计算
    func mineMonthlyCostConverted(to target: CurrencyCode, rates: [String: Double]) -> Double {
        monthlyCostConverted(to: target, rates: rates) * shareFraction
    }
}
