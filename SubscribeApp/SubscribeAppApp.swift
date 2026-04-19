import SwiftUI
import SwiftData

@main
struct SubscribeAppApp: App {
    @StateObject private var settings = AppSettings.shared

    var container: ModelContainer = AppGroup.makeContainer()

    init() {
        // 进程启动时注册一次后台刷新任务处理器（必须在 App init 中,
        // 而非 .task 中,后者会随每个 WindowGroup 触发)。
        BackgroundRefreshManager.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .task {
                    if ProcessInfo.processInfo.environment["FORCE_SEED"] == "1" {
                        SampleData.ensureSeeded(context: container.mainContext)
                    }
                    await ExchangeRateService.shared.refreshIfStale()
                    await NotificationScheduler.shared.scheduleAll(context: container.mainContext, settings: .shared)
                    await TrialActivityManager.shared.syncAll(context: container.mainContext)
                    await WebhookSweeper.shared.sweep(context: container.mainContext, settings: .shared)
                    WidgetReloader.reload()
                    // 每次 App 进入前台都重新排一次后台刷新,确保系统有最新的请求。
                    BackgroundRefreshManager.shared.schedule()
                }
        }
        .modelContainer(container)
    }
}
