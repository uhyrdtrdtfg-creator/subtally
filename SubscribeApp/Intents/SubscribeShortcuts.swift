import Foundation
import AppIntents

struct SubscribeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextBillIntent(),
            phrases: [
                "\(.applicationName) 下次扣款",
                "\(.applicationName) 查订阅",
                "Show next bill in \(.applicationName)"
            ],
            shortTitle: "下次扣款",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: MonthlyTotalIntent(),
            phrases: [
                "\(.applicationName) 本月支出",
                "\(.applicationName) 本月订阅",
                "Monthly total in \(.applicationName)"
            ],
            shortTitle: "本月支出",
            systemImageName: "yensign.circle"
        )
        AppShortcut(
            intent: AddSubscriptionIntent(),
            phrases: [
                "\(.applicationName) 添加订阅",
                "Add subscription with \(.applicationName)"
            ],
            shortTitle: "添加订阅",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: ShowSubscriptionIntent(),
            phrases: [
                "\(.applicationName) 查询 \(\.$subscription)"
            ],
            shortTitle: "查询订阅",
            systemImageName: "magnifyingglass"
        )
    }
}
