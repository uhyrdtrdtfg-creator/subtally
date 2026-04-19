import WidgetKit
import SwiftData
import Foundation

struct SubSnapshot: Identifiable {
    let id: UUID
    let name: String
    let price: Double
    let currency: CurrencyCode
    let cycle: BillingCycle
    let nextDate: Date
    let category: SubscriptionCategory
    let colorHex: String
    let letter: String
    let slug: String
    let isFreeTrial: Bool
    let trialEndDate: Date?

    var days: Int {
        let cal = Calendar(identifier: .gregorian)
        let a = cal.startOfDay(for: Date())
        let b = cal.startOfDay(for: nextDate)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    var trialDays: Int? {
        guard isFreeTrial, let end = trialEndDate else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let a = cal.startOfDay(for: Date())
        let b = cal.startOfDay(for: end)
        return cal.dateComponents([.day], from: a, to: b).day
    }
}

struct SubEntry: TimelineEntry {
    let date: Date
    let items: [SubSnapshot]
    let monthlyCNY: Double

    static let placeholder = SubEntry(
        date: Date(),
        items: [
            SubSnapshot(id: UUID(), name: "Netflix", price: 68, currency: .cny, cycle: .month,
                        nextDate: Date().addingTimeInterval(86400 * 2), category: .video,
                        colorHex: "E50914", letter: "N", slug: "netflix", isFreeTrial: false, trialEndDate: nil),
            SubSnapshot(id: UUID(), name: "Spotify", price: 30, currency: .cny, cycle: .month,
                        nextDate: Date().addingTimeInterval(86400 * 5), category: .music,
                        colorHex: "1DB954", letter: "S", slug: "spotify", isFreeTrial: false, trialEndDate: nil),
            SubSnapshot(id: UUID(), name: "ChatGPT Plus", price: 20, currency: .usd, cycle: .month,
                        nextDate: Date().addingTimeInterval(86400 * 8), category: .ai,
                        colorHex: "10A37F", letter: "G", slug: "openai", isFreeTrial: false, trialEndDate: nil),
        ],
        monthlyCNY: 801
    )
}

struct SubProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SubEntry) -> Void) {
        Task { @MainActor in
            completion(fetchEntry() ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry() ?? .placeholder
            let nextUpdate = Calendar(identifier: .gregorian).date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    @MainActor
    private func fetchEntry() -> SubEntry? {
        let container = AppGroup.makeContainer()
        let context = container.mainContext
        let descriptor = FetchDescriptor<Subscription>(sortBy: [.init(\.nextBillingDate)])
        guard let subs = try? context.fetch(descriptor) else { return nil }

        let effectiveRate = AppGroup.usdCnyRate

        let snapshots = subs.map { s in
            SubSnapshot(
                id: UUID(),
                name: s.name,
                price: s.price,
                currency: s.currency,
                cycle: s.cycle,
                nextDate: s.nextBillingDate,
                category: s.category,
                colorHex: s.brandColorHex,
                letter: s.fallbackLetter,
                slug: s.slug,
                isFreeTrial: s.isFreeTrial,
                trialEndDate: s.trialEndDate
            )
        }
        let monthly = subs.reduce(0.0) { $0 + $1.mineMonthlyCostCNY(usdRate: effectiveRate) }
        return SubEntry(date: Date(), items: snapshots, monthlyCNY: monthly)
    }
}
