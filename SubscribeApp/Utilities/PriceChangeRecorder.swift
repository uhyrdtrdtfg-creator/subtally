import Foundation
import SwiftData

@MainActor
enum PriceChangeRecorder {
    static func record(
        sub: Subscription,
        oldPrice: Double,
        newPrice: Double,
        oldCurrency: CurrencyCode,
        newCurrency: CurrencyCode,
        context: ModelContext
    ) {
        guard oldPrice > 0 else { return }
        guard oldPrice != newPrice || oldCurrency != newCurrency else { return }

        let change = PriceChange(
            subID: sub.stableID,
            subName: sub.name,
            oldPrice: oldPrice,
            newPrice: newPrice,
            currency: newCurrency,
            cycle: sub.cycle
        )
        context.insert(change)
        try? context.save()
        // Webhook fire is scheduled by the caller (AddEditSubscriptionView)
        // alongside other event fires, so the model object stays valid in scope.
    }

    static func recent(for subID: String, limit: Int = 12, context: ModelContext) -> [PriceChange] {
        var descriptor = FetchDescriptor<PriceChange>(
            predicate: #Predicate { $0.subID == subID },
            sortBy: [SortDescriptor(\.changedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }
}
