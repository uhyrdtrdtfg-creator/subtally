import Foundation
import AppIntents
import SwiftData

// MARK: - SubscriptionEntity

struct SubscriptionEntity: AppEntity, Identifiable {
    var id: String
    var name: String
    var priceText: String
    var nextBillingDateText: String
    var categoryDisplay: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "订阅")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(priceText) · \(nextBillingDateText)"
        )
    }

    static var defaultQuery = SubscriptionQuery()
}

extension SubscriptionEntity {
    init(from sub: Subscription) {
        let formatter = SubscriptionEntityFormatters.dateFormatter
        let priceFormatter = SubscriptionEntityFormatters.priceFormatter
        let symbol = sub.currency.symbol
        let priceNumber = NSNumber(value: sub.price)
        let priceStr = priceFormatter.string(from: priceNumber) ?? String(format: "%.2f", sub.price)
        let cycleSuffix = sub.cycle == .month ? "/月" : "/年"

        self.id = sub.stableID
        self.name = sub.name
        self.priceText = "\(symbol)\(priceStr)\(cycleSuffix)"
        self.nextBillingDateText = formatter.string(from: sub.nextBillingDate)
        self.categoryDisplay = sub.category.displayName
    }
}

// MARK: - SubscriptionQuery

struct SubscriptionQuery: EntityQuery {
    func entities(for identifiers: [SubscriptionEntity.ID]) async throws -> [SubscriptionEntity] {
        await MainActor.run {
            let context = AppGroup.makeContainer().mainContext
            let descriptor = FetchDescriptor<Subscription>()
            guard let all = try? context.fetch(descriptor) else { return [] }
            let idSet = Set(identifiers)
            return all
                .filter { idSet.contains($0.stableID) }
                .map { SubscriptionEntity(from: $0) }
        }
    }

    func suggestedEntities() async throws -> [SubscriptionEntity] {
        await MainActor.run {
            let context = AppGroup.makeContainer().mainContext
            let descriptor = FetchDescriptor<Subscription>(
                sortBy: [SortDescriptor(\Subscription.nextBillingDate, order: .forward)]
            )
            guard let all = try? context.fetch(descriptor) else { return [] }
            return Array(all.prefix(5)).map { SubscriptionEntity(from: $0) }
        }
    }
}

// MARK: - Shared formatters

enum SubscriptionEntityFormatters {
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }()

    static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
}
