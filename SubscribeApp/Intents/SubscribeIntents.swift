import Foundation
import AppIntents
import SwiftData

// MARK: - AppEnums

enum CurrencyCodeEnum: String, AppEnum {
    case cny = "CNY"
    case usd = "USD"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "币种")
    static var caseDisplayRepresentations: [CurrencyCodeEnum: DisplayRepresentation] = [
        .cny: DisplayRepresentation(title: "人民币"),
        .usd: DisplayRepresentation(title: "美元")
    ]

    var asCurrencyCode: CurrencyCode {
        switch self {
        case .cny: return .cny
        case .usd: return .usd
        }
    }
}

enum BillingCycleEnum: String, AppEnum {
    case month
    case year

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "计费周期")
    static var caseDisplayRepresentations: [BillingCycleEnum: DisplayRepresentation] = [
        .month: DisplayRepresentation(title: "按月"),
        .year: DisplayRepresentation(title: "年度")
    ]

    var asBillingCycle: BillingCycle {
        switch self {
        case .month: return .month
        case .year: return .year
        }
    }
}

// MARK: - Helpers

private enum SubscribeIntentHelpers {
    @MainActor
    static func fetchAll() -> [Subscription] {
        let context = AppGroup.makeContainer().mainContext
        let descriptor = FetchDescriptor<Subscription>()
        return (try? context.fetch(descriptor)) ?? []
    }

    @MainActor
    static func fetchEarliest() -> Subscription? {
        let context = AppGroup.makeContainer().mainContext
        var descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.nextBillingDate, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func priceText(for sub: Subscription) -> String {
        let f = SubscriptionEntityFormatters.priceFormatter
        let priceNumber = NSNumber(value: sub.price)
        let str = f.string(from: priceNumber) ?? String(format: "%.2f", sub.price)
        let suffix = sub.cycle == .month ? "/月" : "/年"
        return "\(sub.currency.symbol)\(str)\(suffix)"
    }

    static func formatTotal(_ value: Double) -> String {
        let f = SubscriptionEntityFormatters.priceFormatter
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - NextBillIntent

struct NextBillIntent: AppIntent {
    static var title: LocalizedStringResource = "显示下次扣款"
    static var description = IntentDescription("查看最近要扣费的订阅")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let sub = SubscribeIntentHelpers.fetchEarliest() else {
            return .result(dialog: IntentDialog("你目前没有待扣费的订阅"))
        }
        let priceText = SubscribeIntentHelpers.priceText(for: sub)
        let days = sub.daysUntilNext()
        let dateShort = SubscriptionEntityFormatters.shortDateFormatter.string(from: sub.nextBillingDate)
        let dialog = IntentDialog("下次扣款：\(sub.name) \(priceText)，\(days)天后(\(dateShort))")
        return .result(dialog: dialog)
    }
}

// MARK: - MonthlyTotalIntent

struct MonthlyTotalIntent: AppIntent {
    static var title: LocalizedStringResource = "本月订阅总支出"
    static var description = IntentDescription("查看本月所有订阅折算后的总支出")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let all = SubscribeIntentHelpers.fetchAll()
        guard !all.isEmpty else {
            return .result(dialog: IntentDialog("你还没有添加任何订阅"))
        }
        let rate = AppGroup.usdCnyRate
        let total = all.reduce(0.0) { $0 + $1.mineMonthlyCostCNY(usdRate: rate) }
        let totalStr = SubscribeIntentHelpers.formatTotal(total)
        let dialog = IntentDialog("本月 \(all.count) 个订阅共 ¥\(totalStr)")
        return .result(dialog: dialog)
    }
}

// MARK: - AddSubscriptionIntent

struct AddSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "添加订阅"
    static var description = IntentDescription("快速添加一个新订阅")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "名称")
    var name: String

    @Parameter(title: "金额")
    var amount: Double

    @Parameter(title: "币种", default: .cny)
    var currency: CurrencyCodeEnum

    @Parameter(title: "计费周期", default: .month)
    var cycle: BillingCycleEnum

    @Parameter(title: "下次扣款日期")
    var nextDate: Date

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppGroup.makeContainer().mainContext
        let letter = String(name.prefix(1)).uppercased()
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let sub = Subscription(
            name: name,
            category: .work,
            price: amount,
            currency: currency.asCurrencyCode,
            cycle: cycle.asBillingCycle,
            nextBillingDate: nextDate,
            slug: slug,
            brandColorHex: "888888",
            fallbackLetter: letter.isEmpty ? "•" : letter
        )
        context.insert(sub)
        try? context.save()

        let priceText = SubscribeIntentHelpers.priceText(for: sub)
        let dialog = IntentDialog("已添加：\(name) \(priceText)")
        return .result(dialog: dialog)
    }
}

// MARK: - ShowSubscriptionIntent

struct ShowSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "查看订阅"
    static var description = IntentDescription("查询某个订阅的详情")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "订阅")
    var subscription: SubscriptionEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialog = IntentDialog("\(subscription.name)：\(subscription.priceText)，下次扣款 \(subscription.nextBillingDateText)")
        return .result(dialog: dialog)
    }
}
