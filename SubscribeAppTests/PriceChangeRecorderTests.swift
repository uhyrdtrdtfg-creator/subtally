import XCTest
import SwiftData
@testable import Subtally

/// Exercises `PriceChangeRecorder` against an in-memory SwiftData container.
/// All entry points are `@MainActor`, so the test methods must be too.
@MainActor
final class PriceChangeRecorderTests: XCTestCase {

    // MARK: - Helpers

    /// Build a fresh in-memory ModelContainer so each test is hermetic.
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Subscription.self, PriceChange.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeSub(name: String = "Spotify", price: Double = 10) -> Subscription {
        Subscription(
            name: name,
            category: .music,
            price: price,
            currency: .cny,
            cycle: .month,
            nextBillingDate: Date(),
            slug: name.lowercased(),
            brandColorHex: "888888",
            fallbackLetter: String(name.prefix(1))
        )
    }

    private func priceChangeCount(_ ctx: ModelContext) throws -> Int {
        try ctx.fetchCount(FetchDescriptor<PriceChange>())
    }

    // MARK: - Tests

    func test_record_skipsWhenOldPriceIsZero() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 12)
        ctx.insert(sub)

        PriceChangeRecorder.record(
            sub: sub,
            oldPrice: 0,
            newPrice: 12,
            oldCurrency: .cny,
            newCurrency: .cny,
            context: ctx
        )

        XCTAssertEqual(try priceChangeCount(ctx), 0, "Initial creation (oldPrice == 0) must not record a change")
    }

    func test_record_skipsWhenPriceAndCurrencyUnchanged() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 12)
        ctx.insert(sub)

        PriceChangeRecorder.record(
            sub: sub,
            oldPrice: 12,
            newPrice: 12,
            oldCurrency: .cny,
            newCurrency: .cny,
            context: ctx
        )

        XCTAssertEqual(try priceChangeCount(ctx), 0, "No-op edits must not be recorded")
    }

    func test_record_writesWhenPriceChanges() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 15)
        ctx.insert(sub)

        PriceChangeRecorder.record(
            sub: sub,
            oldPrice: 10,
            newPrice: 15,
            oldCurrency: .cny,
            newCurrency: .cny,
            context: ctx
        )

        let changes = PriceChangeRecorder.recent(for: sub.stableID, context: ctx)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.oldPrice, 10)
        XCTAssertEqual(changes.first?.newPrice, 15)
        XCTAssertEqual(changes.first?.currency, .cny)
    }

    func test_record_writesWhenCurrencyChangesButPriceSame() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 10)
        ctx.insert(sub)

        PriceChangeRecorder.record(
            sub: sub,
            oldPrice: 10,
            newPrice: 10,
            oldCurrency: .cny,
            newCurrency: .usd,
            context: ctx
        )

        let changes = PriceChangeRecorder.recent(for: sub.stableID, context: ctx)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.currency, .usd, "New currency must be persisted")
    }

    func test_recent_returnsSortedDescendingByChangedAt() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 10)
        ctx.insert(sub)

        // Insert three changes back-to-back; SwiftData stamps changedAt at init.
        // Force ordering by sleeping a beat between writes.
        for (old, new) in [(10.0, 11.0), (11.0, 12.0), (12.0, 13.0)] {
            PriceChangeRecorder.record(
                sub: sub,
                oldPrice: old, newPrice: new,
                oldCurrency: .cny, newCurrency: .cny,
                context: ctx
            )
            // Tiny sleep to guarantee monotonically increasing changedAt
            // even on machines with low-resolution clocks.
            Thread.sleep(forTimeInterval: 0.01)
        }

        let recent = PriceChangeRecorder.recent(for: sub.stableID, context: ctx)
        XCTAssertEqual(recent.count, 3)
        // Newest first: 12 -> 13 must precede 11 -> 12 must precede 10 -> 11.
        XCTAssertEqual(recent.map(\.newPrice), [13, 12, 11])
        // And explicit ordering check on the timestamps.
        for i in 0..<recent.count - 1 {
            XCTAssertGreaterThanOrEqual(recent[i].changedAt, recent[i + 1].changedAt)
        }
    }

    func test_recent_filtersBySubID_whenTwoSubsBothHaveChanges() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let a = makeSub(name: "A", price: 10)
        let b = makeSub(name: "B", price: 20)
        ctx.insert(a); ctx.insert(b)

        // 2 changes for A, 1 for B
        PriceChangeRecorder.record(sub: a, oldPrice: 10, newPrice: 11,
                                   oldCurrency: .cny, newCurrency: .cny, context: ctx)
        PriceChangeRecorder.record(sub: a, oldPrice: 11, newPrice: 12,
                                   oldCurrency: .cny, newCurrency: .cny, context: ctx)
        PriceChangeRecorder.record(sub: b, oldPrice: 20, newPrice: 25,
                                   oldCurrency: .cny, newCurrency: .cny, context: ctx)

        let aChanges = PriceChangeRecorder.recent(for: a.stableID, context: ctx)
        let bChanges = PriceChangeRecorder.recent(for: b.stableID, context: ctx)

        XCTAssertEqual(aChanges.count, 2)
        XCTAssertEqual(bChanges.count, 1)
        XCTAssertTrue(aChanges.allSatisfy { $0.subID == a.stableID })
        XCTAssertTrue(bChanges.allSatisfy { $0.subID == b.stableID })
    }

    func test_recent_respectsLimit() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let sub = makeSub(price: 1)
        ctx.insert(sub)

        for i in 1...5 {
            PriceChangeRecorder.record(
                sub: sub,
                oldPrice: Double(i), newPrice: Double(i + 1),
                oldCurrency: .cny, newCurrency: .cny,
                context: ctx
            )
            Thread.sleep(forTimeInterval: 0.005)
        }

        let limited = PriceChangeRecorder.recent(for: sub.stableID, limit: 2, context: ctx)
        XCTAssertEqual(limited.count, 2, "Limit parameter must cap the result count")
    }
}
