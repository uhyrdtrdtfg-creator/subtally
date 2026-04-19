import Foundation
import BackgroundTasks
import SwiftData

/// 后台刷新管理：通过 BGAppRefreshTask 在 App 处于后台时
/// 周期性地刷新汇率并触发 webhook 扫描（bill.upcoming / trial.expiring）。
@MainActor
final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskID = "com.samxiao.SubscribeApp.refresh"

    private var didRegister = false

    private init() {}

    /// 注册后台任务处理器。须在 App 启动时调用一次（进程级别，非每个 Window）。
    /// 多次调用会被忽略，保证幂等。
    func register() {
        guard !didRegister else { return }
        didRegister = true

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskID,
            using: nil
        ) { task in
            // BGTaskScheduler 在主线程回调，但闭包不带 actor 标注，
            // 因此显式跳到 MainActor 后再调度异步工作。
            Task { @MainActor in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                await Self.shared.handle(task: refreshTask)
            }
        }
    }

    /// 提交下一次后台刷新请求；earliestBeginDate 设为 4 小时之后。
    /// 重复调用是安全的：BGTaskScheduler 会自动用最新一次替换。
    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskID)
        request.earliestBeginDate = Date().addingTimeInterval(4 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("BackgroundRefreshManager.schedule failed: \(error)")
            #endif
        }
    }

    // MARK: - Private

    private func handle(task: BGAppRefreshTask) async {
        // 先排下一次，确保即使本次失败也保持周期性。
        schedule()

        // 用一个一次性的 ModelContainer 取主上下文。BGTask 进程已在 App 内，
        // AppGroup.makeContainer() 会复用 sharedDefaults / 同样的存储位置。
        let container = AppGroup.makeContainer()
        let context = container.mainContext
        let settings = AppSettings.shared

        // 取消信号到达时立即标记失败并退出，避免被系统杀掉。
        let workItem = Task { @MainActor in
            await ExchangeRateService.shared.refreshIfStale()
            await WebhookSweeper.shared.sweep(context: context, settings: settings)
        }

        task.expirationHandler = {
            workItem.cancel()
        }

        await workItem.value
        task.setTaskCompleted(success: !workItem.isCancelled)
    }
}
