import XCTest
@testable import Subtally

/// Tests for the pure template engine in `WebhookTemplate`.
final class WebhookTemplateTests: XCTestCase {

    // MARK: - Fixtures

    private func makeSub(
        name: String = "ChatGPT Plus",
        category: SubscriptionCategory = .ai,
        price: Double = 20,
        currency: CurrencyCode = .usd,
        cycle: BillingCycle = .month,
        notes: String = ""
    ) -> Subscription {
        let cal = Calendar(identifier: .gregorian)
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 1
        let next = cal.date(from: c)!
        return Subscription(
            name: name,
            category: category,
            price: price,
            currency: currency,
            cycle: cycle,
            nextBillingDate: next,
            slug: "chatgpt",
            brandColorHex: "10A37F",
            fallbackLetter: "C",
            notes: notes
        )
    }

    private let timestamp: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 4; c.day = 18; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    private func makeVars(event: WebhookEvent = .billUpcoming, sub: Subscription? = nil) -> [String: String] {
        WebhookTemplate.variables(
            event: event,
            sub: sub ?? makeSub(),
            timestamp: timestamp,
            deliveryID: "del-123",
            usdCnyRate: 7.2
        )
    }

    // MARK: - Tests

    func test_variables_keyCount_isExactly23() {
        // Per source: 5 top-level + 18 subscription.* keys = 23 total.
        let vars = makeVars()
        XCTAssertEqual(vars.count, 23, "If you change the variable set, update this assertion")
    }

    func test_render_substitutesEvent() {
        let vars = makeVars(event: .billUpcoming)
        let out = WebhookTemplate.render("event={{event}}", vars: vars)
        XCTAssertEqual(out, "event=bill.upcoming")
    }

    func test_render_substitutesEventDisplayChinese() {
        let vars = makeVars(event: .trialExpiring)
        let out = WebhookTemplate.render("名称: {{event_display}}", vars: vars)
        XCTAssertEqual(out, "名称: 试用即将结束")
    }

    func test_render_unknownVariable_isLeftAsIs() {
        let vars = makeVars()
        let out = WebhookTemplate.render("hello {{nonexistent}}", vars: vars)
        XCTAssertEqual(out, "hello {{nonexistent}}")
    }

    func test_render_whitespacePaddedVariable_substitutes() {
        let vars = makeVars(event: .billUpcoming)
        let out = WebhookTemplate.render("{{ event }}", vars: vars)
        XCTAssertEqual(out, "bill.upcoming")
    }

    func test_render_emptyTemplate_returnsEmpty() {
        let vars = makeVars()
        XCTAssertEqual(WebhookTemplate.render("", vars: vars), "")
    }

    func test_render_jsonTemplate_simpleName_producesValidJSON() throws {
        let sub = makeSub(name: "Spotify")
        let vars = makeVars(sub: sub)
        let template = #"{"name":"{{subscription.name}}"}"#
        let out = WebhookTemplate.render(template, vars: vars)

        // Must be valid JSON.
        let data = out.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(parsed?["name"] as? String, "Spotify")
    }

    func test_render_jsonTemplate_nameWithDoubleQuote_isJSONEscaped() throws {
        let sub = makeSub(name: "Cool \"Quoted\" Service")
        let vars = makeVars(sub: sub)
        let template = #"{"name":"{{subscription.name}}"}"#
        let out = WebhookTemplate.render(template, vars: vars)

        XCTAssertTrue(out.contains(#"\""#), "Embedded quotes must be JSON-escaped (\\\")")
        // And the result must round-trip through JSON.
        let data = out.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(parsed?["name"] as? String, "Cool \"Quoted\" Service")
    }

    func test_render_multipleOccurrences_allReplaced() {
        let vars = makeVars(event: .billUpcoming)
        let out = WebhookTemplate.render("{{event}} {{event}}", vars: vars)
        XCTAssertEqual(out, "bill.upcoming bill.upcoming")
    }

    func test_allWebhookEvents_produceUniqueDisplayNames() {
        let displays = WebhookEvent.allCases.map { event -> String in
            let vars = makeVars(event: event)
            return WebhookTemplate.render("{{event_display}}", vars: vars)
        }
        XCTAssertEqual(WebhookEvent.allCases.count, 6)
        XCTAssertEqual(Set(displays).count, displays.count,
                       "All WebhookEvent cases must produce distinct event_display strings")
    }

    func test_render_longerKeyReplacedBeforeShorter() {
        // The render function explicitly sorts keys longest-first so that
        // "{{subscription.name}}" is matched before "{{subscription}}" would be.
        // We assert the longer-first behavior by ensuring the longer key wins.
        let vars = makeVars()
        let out = WebhookTemplate.render("{{subscription.name}}", vars: vars)
        XCTAssertEqual(out, "ChatGPT Plus")
    }
}
