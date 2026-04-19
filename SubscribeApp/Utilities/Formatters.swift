import Foundation

enum Fmt {
    static func money(_ v: Double, _ ccy: CurrencyCode) -> String {
        let sym = ccy.symbol
        let rounded = abs(v - v.rounded()) < 0.01
        if rounded { return sym + String(Int(v.rounded())) }
        return sym + String(format: "%.2f", v)
    }

    /// Convert a CNY amount into the chosen display currency using the global rates dict.
    /// `usdCnyRate` is kept for back-compat callers but ignored — multi-currency aware.
    static func displayMoney(cnyAmount: Double, in display: CurrencyCode, usdCnyRate: Double = 0) -> String {
        if display == .cny { return money(cnyAmount, .cny) }
        let converted = AppGroup.convert(cnyAmount, from: "CNY", to: display.rawValue)
        return money(converted, display)
    }

    static func displayInt(cnyAmount: Double, in display: CurrencyCode, usdCnyRate: Double = 0) -> String {
        let amount: Double
        if display == .cny {
            amount = cnyAmount
        } else {
            amount = AppGroup.convert(cnyAmount, from: "CNY", to: display.rawValue)
        }
        return display.symbol + thousandsInt(Int(amount.rounded()))
    }

    static func shortDate(_ d: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.month, .day], from: d)
        return "\(c.month ?? 0)月\(c.day ?? 0)日"
    }

    static func longDate(_ d: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: d)
        let dow = ["周日","周一","周二","周三","周四","周五","周六"][max(0, (c.weekday ?? 1) - 1)]
        return "\(c.year ?? 0)年\(c.month ?? 0)月\(c.day ?? 0)日 · \(dow)"
    }

    static func monthTitle(_ d: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month], from: d)
        return "\(c.year ?? 0)年\(c.month ?? 0)月"
    }

    static func thousandsInt(_ v: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    static func daysText(_ d: Int) -> String {
        if d < 0 { return "\(-d)d 前" }
        if d == 0 { return "今天" }
        return "in \(d)d"
    }
}
