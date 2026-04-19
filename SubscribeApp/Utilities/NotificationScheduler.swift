import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func scheduleAll(context: ModelContext, settings: AppSettings) async {
        guard settings.notificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized || status.authorizationStatus == .provisional else { return }

        center.removeAllPendingNotificationRequests()

        let descriptor = FetchDescriptor<Subscription>()
        guard let subs = try? context.fetch(descriptor) else { return }

        let cal = Calendar(identifier: .gregorian)
        let now = Date()

        for sub in subs {
            // Free trial: warn 2 days before trial ends + day of
            if sub.isFreeTrial, let end = sub.trialEndDate {
                for lead in [2, 0] {
                    guard let fire = fireDate(base: end, leadDays: lead, hour: settings.reminderHour, cal: cal),
                          fire > now else { continue }
                    let content = UNMutableNotificationContent()
                    content.title = "⚠️ 免费试用即将结束"
                    content.body = lead == 0
                        ? "\(sub.name) 今天试用到期，不想续费记得退订"
                        : "\(sub.name) \(lead) 天后试用结束，确认是否要继续"
                    content.sound = .default
                    schedule(content: content, at: fire, id: "trial-\(sub.stableID)-\(lead)")
                }
            }

            // Regular billing reminder
            guard let fire = fireDate(base: sub.nextBillingDate, leadDays: settings.reminderLeadDays, hour: settings.reminderHour, cal: cal),
                  fire > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "订阅到期提醒"
            content.body = "\(sub.name) · \(Fmt.money(sub.price, sub.currency)) · \(settings.reminderLeadDays) 天后扣款"
            content.sound = .default
            schedule(content: content, at: fire, id: "bill-\(sub.stableID)")
        }
    }

    private func fireDate(base: Date, leadDays: Int, hour: Int, cal: Calendar) -> Date? {
        guard let shifted = cal.date(byAdding: .day, value: -leadDays, to: base) else { return nil }
        var comps = cal.dateComponents([.year, .month, .day], from: shifted)
        comps.hour = hour
        comps.minute = 0
        return cal.date(from: comps)
    }

    private func schedule(content: UNNotificationContent, at date: Date, id: String) {
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

