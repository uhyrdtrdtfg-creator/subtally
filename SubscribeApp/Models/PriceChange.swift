import Foundation
import SwiftData

@Model
final class PriceChange {
    var id: String = UUID().uuidString
    var subID: String = ""
    var subName: String = ""
    var oldPrice: Double = 0
    var newPrice: Double = 0
    var currencyRaw: String = CurrencyCode.cny.rawValue
    var cycleRaw: String = BillingCycle.month.rawValue
    var changedAt: Date = Date()

    init(
        subID: String,
        subName: String,
        oldPrice: Double,
        newPrice: Double,
        currency: CurrencyCode,
        cycle: BillingCycle
    ) {
        self.id = UUID().uuidString
        self.subID = subID
        self.subName = subName
        self.oldPrice = oldPrice
        self.newPrice = newPrice
        self.currencyRaw = currency.rawValue
        self.cycleRaw = cycle.rawValue
        self.changedAt = Date()
    }

    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .cny }
        set { currencyRaw = newValue.rawValue }
    }

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRaw) ?? .month }
        set { cycleRaw = newValue.rawValue }
    }

    var deltaPercent: Double {
        guard oldPrice != 0 else { return 0 }
        return (newPrice - oldPrice) / oldPrice * 100
    }

    enum Direction {
        case up
        case down
        case flat
    }

    var direction: Direction {
        let pct = deltaPercent
        if abs(pct) < 0.5 { return .flat }
        return pct > 0 ? .up : .down
    }
}
