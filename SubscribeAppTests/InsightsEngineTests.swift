import XCTest
@testable import Subtally

/// One test per rule R1–R6. `InsightsEngine.analyze` is a pure function so
/// we can build `Subscription` instances directly without a SwiftData container.
final class InsightsEngineTests: XCTestCase {

    // MARK: - Constants

    /// The fixed "today" used across tests so trial windows are deterministic.
    private let today: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 4; c.day = 18
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private let usdCnyRate: Double = 7.2

    // MARK: - Sub builder

    private func makeSub(
        name: String,
        category: SubscriptionCategory = .work,
        price: Double,
        currency: CurrencyCode = .cny,
        cycle: BillingCycle = .month,
        nextBillingOffsetDays: Int = 30,
        isTrial: Bool = false,
        trialEndOffsetDays: Int? = nil
    ) -> Subscription {
        let cal = Calendar(identifier: .gregorian)
        let nextDate = cal.date(byAdding: .day, value: nextBillingOffsetDays, to: today)!
        let trialEnd = trialEndOffsetDays.flatMap { cal.date(byAdding: .day, value: $0, to: today) }
        return Subscription(
            name: name,
            category: category,
            price: price,
            currency: currency,
            cycle: cycle,
            nextBillingDate: nextDate,
            slug: name.lowercased(),
            brandColorHex: "888888",
            fallbackLetter: String(name.prefix(1)),
            notes: "",
            isFreeTrial: isTrial,
            trialEndDate: trialEnd
        )
    }

    // MARK: - R1: duplicate category

    func test_R1_threeVideoSubsOver50CNY_emitsDuplicateCategoryWarning() {
        let subs: [Subscription] = [
            makeSub(name: "Netflix",  category: .video, price: 30, cycle: .month),
            makeSub(name: "Bilibili", category: .video, price: 25, cycle: .month),
            makeSub(name: "iQiyi",    category: .video, price: 20, cycle: .month),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let dupes = result.filter { $0.title.contains("重复分类") }
        XCTAssertEqual(dupes.count, 1)
        XCTAssertEqual(dupes.first?.severity, .warning)
        XCTAssertTrue(dupes.first?.title.contains("视频") ?? false)
    }

    // MARK: - R2: yearly savings recommendation for monthly subs > 240 CNY/yr

    func test_R2_monthlySubOver240PerYear_emitsYearlySavingsInfo() {
        let subs: [Subscription] = [
            // 25/month -> 300/yr CNY -> > 240 trigger
            makeSub(name: "ChatGPT Plus", price: 25, cycle: .month),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let yearly = result.filter { $0.title.contains("考虑年付") }
        XCTAssertEqual(yearly.count, 1)
        XCTAssertEqual(yearly.first?.severity, .info)
        // Body must mention the savings range.
        XCTAssertTrue(yearly.first?.body.contains("15-20%") ?? false)
    }

    // MARK: - R3: top-1 share > 30%

    func test_R3_topOneOverThirtyPercent_emitsConcentrationInfo() {
        // Make one sub dominate: 100 vs 10 + 5 -> 100/115 ~= 87%.
        let subs: [Subscription] = [
            makeSub(name: "Big",   price: 100, cycle: .month),
            makeSub(name: "Small", price: 10,  cycle: .month),
            makeSub(name: "Tiny",  price: 5,   cycle: .month),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let conc = result.filter { $0.title == "支出集中度" }
        XCTAssertEqual(conc.count, 1)
        XCTAssertEqual(conc.first?.severity, .info)
        XCTAssertTrue(conc.first?.body.contains("Big") ?? false)
    }

    // MARK: - R4: trial accumulation > 100 CNY

    func test_R4_threeActiveTrialsOver100CNY_emitsTrialWarning() {
        let subs: [Subscription] = [
            makeSub(name: "Trial A", price: 50, cycle: .month, isTrial: true, trialEndOffsetDays: 5),
            makeSub(name: "Trial B", price: 40, cycle: .month, isTrial: true, trialEndOffsetDays: 7),
            makeSub(name: "Trial C", price: 30, cycle: .month, isTrial: true, trialEndOffsetDays: 3),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let trials = result.filter { $0.title == "试用即将扣费" }
        XCTAssertEqual(trials.count, 1)
        XCTAssertEqual(trials.first?.severity, .warning)
        XCTAssertTrue(trials.first?.body.contains("3 个") ?? false)
    }

    // MARK: - R5: USD share > 30%

    func test_R5_usdShareOverThirtyPercent_emitsUSDExposureInfo() {
        // 1 USD sub at $10 -> 72 CNY/month.
        // 1 CNY sub at 50 CNY/month.
        // USD share = 72 / 122 ~= 59% which exceeds 30%.
        let subs: [Subscription] = [
            makeSub(name: "OpenAI", price: 10, currency: .usd, cycle: .month),
            makeSub(name: "Local",  price: 50, currency: .cny, cycle: .month),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let usd = result.filter { $0.title == "USD 敞口" }
        XCTAssertEqual(usd.count, 1)
        XCTAssertEqual(usd.first?.severity, .info)
    }

    // MARK: - R6: balanced -> positive info

    func test_R6_balancedPortfolio_emitsHealthyInfo() {
        // Need ≥4 subs across different categories so R3 (top concentration) doesn't fire,
        // R1 (duplicate category) doesn't fire, and overall cost is modest.
        // Use yearly billing to skip R2; CNY-only to skip R5; non-trial to skip R4.
        let subs: [Subscription] = [
            makeSub(name: "S1", category: .work, price: 10, currency: .cny, cycle: .year),
            makeSub(name: "S2", category: .video, price: 12, currency: .cny, cycle: .year),
            makeSub(name: "S3", category: .music, price: 11, currency: .cny, cycle: .year),
            makeSub(name: "S4", category: .cloud, price: 13, currency: .cny, cycle: .year),
        ]
        let result = InsightsEngine.analyze(subs: subs, usdCnyRate: usdCnyRate, today: today)

        let healthy = result.filter { $0.title == "结构均衡" }
        XCTAssertEqual(healthy.count, 1)
        XCTAssertEqual(healthy.first?.severity, .info)
        // No warnings or alerts should fire for this balanced portfolio
        let nonInfo = result.filter { $0.severity != .info }
        XCTAssertTrue(nonInfo.isEmpty, "Expected only positive info for a balanced portfolio, got: \(result.map(\.title))")
    }

    // MARK: - Empty portfolio

    func test_emptyPortfolio_returnsEmpty() {
        let result = InsightsEngine.analyze(subs: [], usdCnyRate: usdCnyRate, today: today)
        XCTAssertTrue(result.isEmpty)
    }
}
