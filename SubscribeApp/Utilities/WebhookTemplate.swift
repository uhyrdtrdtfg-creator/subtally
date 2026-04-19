import Foundation

enum WebhookTemplate {

    static func variables(event: WebhookEvent, sub: Subscription, timestamp: Date, deliveryID: String, usdCnyRate: Double, previousPrice: Double? = nil) -> [String: String] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let days = sub.daysUntilNext(from: timestamp)
        let trialDays = sub.daysUntilTrialEnd(from: timestamp)

        let prevPriceString = previousPrice.map { numString($0) } ?? ""

        return [
            "event": event.rawValue,
            "event_display": event.displayName,
            "timestamp": iso.string(from: timestamp),
            "delivery_id": deliveryID,
            "app": "Subtally iOS",

            "subscription.id": sub.stableID,
            "subscription.name": jsonEscape(sub.name),
            "subscription.category": sub.categoryRaw,
            "subscription.price": numString(sub.price),
            "subscription.price_formatted": jsonEscape(Fmt.money(sub.price, sub.currency)),
            "subscription.currency": sub.currencyRaw,
            "subscription.cycle": sub.cycleRaw,
            "subscription.cycle_display": sub.cycle.displayName,
            "subscription.next_billing_date": iso.string(from: sub.nextBillingDate),
            "subscription.next_billing_date_short": Fmt.shortDate(sub.nextBillingDate),
            "subscription.days_until_next": String(days),
            "subscription.is_free_trial": sub.isFreeTrial ? "true" : "false",
            "subscription.trial_end_date": sub.trialEndDate.map { iso.string(from: $0) } ?? "",
            "subscription.trial_days_remaining": trialDays.map(String.init) ?? "",
            "subscription.notes": jsonEscape(sub.notes),
            "subscription.price_cny": numString(sub.priceInCNY(usdRate: usdCnyRate)),
            "subscription.monthly_cost_cny": numString(sub.monthlyCostCNY(usdRate: usdCnyRate)),
            "subscription.previous_price": prevPriceString,
        ]
    }

    static func render(_ template: String, vars: [String: String]) -> String {
        var out = template
        // sort longest key first so "subscription.name" replaces before "subscription"
        for key in vars.keys.sorted(by: { $0.count > $1.count }) {
            let value = vars[key]!
            out = out.replacingOccurrences(of: "{{\(key)}}", with: value)
            out = out.replacingOccurrences(of: "{{ \(key) }}", with: value)
        }
        return out
    }

    private static func numString(_ v: Double) -> String {
        abs(v - v.rounded()) < 0.001 ? "\(Int(v.rounded()))" : String(format: "%.2f", v)
    }

    /// Escape a string so it can be safely embedded inside a JSON string literal.
    private static func jsonEscape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for c in s {
            switch c {
            case "\\": out.append("\\\\")
            case "\"": out.append("\\\"")
            case "\n": out.append("\\n")
            case "\r": out.append("\\r")
            case "\t": out.append("\\t")
            default:
                if c.asciiValue != nil && c.asciiValue! < 0x20 {
                    out.append(String(format: "\\u%04x", c.asciiValue!))
                } else {
                    out.append(c)
                }
            }
        }
        return out
    }

    // MARK: - Presets

    struct Preset: Identifiable {
        let id: String
        let name: String
        let contentType: String
        let method: WebhookHTTPMethod
        let body: String
    }

    static let presets: [Preset] = [
        .init(
            id: "slack",
            name: "Slack Incoming Webhook",
            contentType: "application/json; charset=utf-8",
            method: .post,
            body: """
{
  "text": ":bell: *{{subscription.name}}* · {{event_display}}",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*{{subscription.name}}* · {{event_display}}\\n金额：{{subscription.price_formatted}}\\n下次扣款：{{subscription.next_billing_date_short}}（{{subscription.days_until_next}} 天后）"
      }
    }
  ]
}
"""
        ),
        .init(
            id: "discord",
            name: "Discord Webhook",
            contentType: "application/json; charset=utf-8",
            method: .post,
            body: """
{
  "username": "Subtally",
  "content": "**{{subscription.name}}** · {{event_display}}",
  "embeds": [
    {
      "title": "{{subscription.name}}",
      "description": "{{event_display}} · {{subscription.cycle_display}}",
      "fields": [
        { "name": "金额", "value": "{{subscription.price_formatted}}", "inline": true },
        { "name": "下次扣款", "value": "{{subscription.next_billing_date_short}}", "inline": true },
        { "name": "剩余天数", "value": "{{subscription.days_until_next}} 天", "inline": true }
      ]
    }
  ]
}
"""
        ),
        .init(
            id: "bark",
            name: "Bark（iOS 推送）",
            contentType: "application/json; charset=utf-8",
            method: .post,
            body: """
{
  "title": "{{subscription.name}} · {{event_display}}",
  "body": "{{subscription.price_formatted}} · {{subscription.next_billing_date_short}}（{{subscription.days_until_next}} 天后扣款）",
  "group": "Subtally",
  "level": "active"
}
"""
        ),
        .init(
            id: "telegram",
            name: "Telegram Bot sendMessage",
            contentType: "application/json; charset=utf-8",
            method: .post,
            body: """
{
  "chat_id": "PUT_YOUR_CHAT_ID_HERE",
  "parse_mode": "Markdown",
  "text": "*{{subscription.name}}* · {{event_display}}\\n金额：{{subscription.price_formatted}}\\n下次扣款：{{subscription.next_billing_date_short}}（{{subscription.days_until_next}} 天后）"
}
"""
        ),
        .init(
            id: "raw",
            name: "原始 JSON（默认结构）",
            contentType: "application/json; charset=utf-8",
            method: .post,
            body: ""
        ),
    ]
}
