import Foundation
import SwiftData

@MainActor
final class WebhookSweeper {
    static let shared = WebhookSweeper()
    private init() {}

    private let dedupDefaults = AppGroup.sharedDefaults

    /// Run on app launch / foreground. Fires bill.upcoming and trial.expiring
    /// with per-day dedup to avoid spamming the same endpoint.
    func sweep(context: ModelContext, settings: AppSettings) async {
        let descriptor = FetchDescriptor<Subscription>()
        guard let subs = try? context.fetch(descriptor) else { return }

        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let leadDays = settings.reminderLeadDays
        let dayKey = isoDayString(today)

        for sub in subs {
            // bill.upcoming: when daysUntilNext == leadDays (within today)
            let billDay = cal.startOfDay(for: sub.nextBillingDate)
            if let diff = cal.dateComponents([.day], from: today, to: billDay).day,
               diff == leadDays, diff >= 0 {
                let dedupKey = "webhook.fired.\(sub.stableID).bill.\(dayKey)"
                if !dedupDefaults.bool(forKey: dedupKey) {
                    await WebhookDispatcher.shared.fire(event: .billUpcoming, sub: sub, context: context, usdCnyRate: settings.usdCnyRate)
                    dedupDefaults.set(true, forKey: dedupKey)
                }
            }

            // trial.expiring: 2 days before or day of trial end
            if sub.isFreeTrial, let end = sub.trialEndDate {
                let endDay = cal.startOfDay(for: end)
                if let diff = cal.dateComponents([.day], from: today, to: endDay).day,
                   diff == 2 || diff == 0 {
                    let dedupKey = "webhook.fired.\(sub.stableID).trial.\(diff).\(dayKey)"
                    if !dedupDefaults.bool(forKey: dedupKey) {
                        await WebhookDispatcher.shared.fire(event: .trialExpiring, sub: sub, context: context, usdCnyRate: settings.usdCnyRate)
                        dedupDefaults.set(true, forKey: dedupKey)
                    }
                }
            }
        }
    }

    private func isoDayString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}
