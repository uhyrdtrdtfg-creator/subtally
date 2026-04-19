import Foundation

// MARK: - Tunable thresholds

private enum InsightThresholds {
    /// R1 重复分类: 同一分类下活跃订阅数量阈值
    static let duplicateCategoryMinCount: Int = 3
    /// R1 重复分类: 该分类月度合计 CNY 触发线
    static let duplicateCategoryMinMonthlyCNY: Double = 50

    /// R2 年付节省: 月付订阅价格(>0) 的年化 CNY 触发线 (~$30/yr)
    static let yearlyEquivalentMinCNY: Double = 240
    /// R2 年付节省: 经验上年付节省比例 (展示用)
    static let yearlyDiscountLowPercent: Int = 15
    static let yearlyDiscountHighPercent: Int = 20

    /// R3 Top 集中度: 单项占比阈值
    static let topOneSharePercent: Double = 0.30
    /// R3 Top 集中度: 前三占比阈值
    static let topThreeSharePercent: Double = 0.60

    /// R4 试用累计: 进行中的试用合计 CNY 触发线
    static let trialTotalCNYThreshold: Double = 100

    /// R5 USD 占比: 美元订阅占总月支出的触发比例
    static let usdShareThresholdPercent: Double = 0.30
}

// MARK: - Insight model

enum InsightSeverity {
    case info
    case warning
    case alert
}

struct Insight: Identifiable {
    let id = UUID()
    let severity: InsightSeverity
    let icon: String
    let title: String
    let body: String
    let suggestion: String?
}

// MARK: - Engine

enum InsightsEngine {

    /// 纯函数: 仅依赖入参，不访问 SwiftData / 全局状态。
    static func analyze(
        subs: [Subscription],
        usdCnyRate: Double,
        today: Date = Date()
    ) -> [Insight] {
        guard !subs.isEmpty else { return [] }

        var insights: [Insight] = []

        // 预计算: 每个订阅的月度 CNY 成本 (不考虑分摊, 看的是订阅本身规模)
        let monthlyCNY: [(sub: Subscription, monthly: Double)] = subs.map { sub in
            (sub, sub.monthlyCostCNY(usdRate: usdCnyRate))
        }
        let totalMonthlyCNY = monthlyCNY.reduce(0) { $0 + $1.monthly }

        // R1 重复分类
        insights.append(contentsOf: ruleDuplicateCategory(monthlyCNY: monthlyCNY))

        // R2 年付节省
        insights.append(contentsOf: ruleYearlySavings(subs: subs, usdRate: usdCnyRate))

        // R3 Top 集中度
        insights.append(contentsOf: ruleTopConcentration(monthlyCNY: monthlyCNY, total: totalMonthlyCNY))

        // R4 试用累计
        insights.append(contentsOf: ruleTrialAccumulation(subs: subs, usdRate: usdCnyRate, today: today))

        // R5 USD 占比
        insights.append(contentsOf: ruleUSDShare(monthlyCNY: monthlyCNY, total: totalMonthlyCNY))

        // R6 健康
        let hasNonInfo = insights.contains { $0.severity != .info }
        if !hasNonInfo {
            insights.append(
                Insight(
                    severity: .info,
                    icon: "checkmark.seal",
                    title: "结构均衡",
                    body: "本月订阅结构均衡，没有发现明显问题。",
                    suggestion: nil
                )
            )
        }

        return insights
    }

    // MARK: - R1 重复分类

    private static func ruleDuplicateCategory(
        monthlyCNY: [(sub: Subscription, monthly: Double)]
    ) -> [Insight] {
        var out: [Insight] = []
        let grouped = Dictionary(grouping: monthlyCNY, by: { $0.sub.category })
        // 稳定排序: 按 rawValue
        let cats = grouped.keys.sorted { $0.rawValue < $1.rawValue }
        for cat in cats {
            guard let entries = grouped[cat] else { continue }
            guard entries.count >= InsightThresholds.duplicateCategoryMinCount else { continue }
            let total = entries.reduce(0) { $0 + $1.monthly }
            guard total > InsightThresholds.duplicateCategoryMinMonthlyCNY else { continue }

            let names = entries
                .sorted { $0.monthly > $1.monthly }
                .prefix(3)
                .map { $0.sub.name }
                .joined(separator: " / ")
            let totalText = Fmt.money(total, .cny)
            let body = "你有 \(entries.count) 个\(cat.displayName)订阅 (\(names))，本月共 \(totalText)，是否有重复内容？"
            out.append(
                Insight(
                    severity: .warning,
                    icon: "rectangle.stack.badge.minus",
                    title: "重复分类: \(cat.displayName)",
                    body: body,
                    suggestion: "考虑合并或停用一项"
                )
            )
        }
        return out
    }

    // MARK: - R2 年付节省

    private static func ruleYearlySavings(
        subs: [Subscription],
        usdRate: Double
    ) -> [Insight] {
        var out: [Insight] = []
        let candidates = subs.filter { $0.cycle == .month && $0.price > 0 }
        var scored: [(Subscription, Double, Double)] = []
        for sub in candidates {
            let monthlyCNY = sub.monthlyCostCNY(usdRate: usdRate)
            let yearlyCNY = monthlyCNY * 12
            if yearlyCNY > InsightThresholds.yearlyEquivalentMinCNY {
                scored.append((sub, monthlyCNY, yearlyCNY))
            }
        }
        scored.sort { lhs, rhs in
            lhs.2 == rhs.2 ? lhs.0.name < rhs.0.name : lhs.2 > rhs.2
        }

        for (sub, monthly, yearly) in scored {
            let monthlyText = Fmt.money(monthly, .cny)
            let yearlyText = Fmt.money(yearly, .cny)
            let body = "\(sub.name) 月付 \(monthlyText)/月，年化 \(yearlyText)。多数服务年付能省 \(InsightThresholds.yearlyDiscountLowPercent)-\(InsightThresholds.yearlyDiscountHighPercent)%。"
            out.append(
                Insight(
                    severity: .info,
                    icon: "calendar.badge.clock",
                    title: "考虑年付: \(sub.name)",
                    body: body,
                    suggestion: "看看年付方案"
                )
            )
        }
        return out
    }

    // MARK: - R3 Top 集中度

    private static func ruleTopConcentration(
        monthlyCNY: [(sub: Subscription, monthly: Double)],
        total: Double
    ) -> [Insight] {
        guard total > 0 else { return [] }
        let sorted = monthlyCNY.sorted { $0.monthly > $1.monthly }
        var out: [Insight] = []

        if let top = sorted.first {
            let share = top.monthly / total
            if share > InsightThresholds.topOneSharePercent {
                let percent = Int((share * 100).rounded())
                let body = "\(top.sub.name) 占你本月支出的 \(percent)%，是最大单项。"
                out.append(
                    Insight(
                        severity: .info,
                        icon: "chart.pie",
                        title: "支出集中度",
                        body: body,
                        suggestion: nil
                    )
                )
            }
        }

        if sorted.count >= 3 {
            let topThree = sorted.prefix(3).reduce(0) { $0 + $1.monthly }
            let share3 = topThree / total
            if share3 > InsightThresholds.topThreeSharePercent {
                let percent = Int((share3 * 100).rounded())
                let names = sorted.prefix(3).map { $0.sub.name }.joined(separator: " / ")
                let body = "前三项 (\(names)) 合计占本月 \(percent)%。"
                out.append(
                    Insight(
                        severity: .info,
                        icon: "chart.bar.xaxis",
                        title: "前三集中",
                        body: body,
                        suggestion: nil
                    )
                )
            }
        }
        return out
    }

    // MARK: - R4 试用累计

    private static func ruleTrialAccumulation(
        subs: [Subscription],
        usdRate: Double,
        today: Date
    ) -> [Insight] {
        // 仅算尚未到期的免费试用 (含今天)
        let active = subs.filter { sub in
            guard sub.isFreeTrial else { return false }
            if let days = sub.daysUntilTrialEnd(from: today) {
                return days >= 0
            }
            // 没设到期日的试用也计入 (无法判断是否结束, 给提醒更安全)
            return true
        }
        guard !active.isEmpty else { return [] }
        let totalCNY = active.reduce(0) { $0 + $1.priceInCNY(usdRate: usdRate) }
        guard totalCNY > InsightThresholds.trialTotalCNYThreshold else { return [] }

        let totalText = Fmt.money(totalCNY, .cny)
        let body = "你有 \(active.count) 个试用即将到期，合计 \(totalText) 即将开始扣款。"
        return [
            Insight(
                severity: .warning,
                icon: "clock.badge.exclamationmark",
                title: "试用即将扣费",
                body: body,
                suggestion: "提前确认是否续订"
            )
        ]
    }

    // MARK: - R5 USD 占比

    private static func ruleUSDShare(
        monthlyCNY: [(sub: Subscription, monthly: Double)],
        total: Double
    ) -> [Insight] {
        guard total > 0 else { return [] }
        let usdEntries = monthlyCNY.filter { $0.sub.currency == .usd }
        guard !usdEntries.isEmpty else { return [] }
        let usdTotal = usdEntries.reduce(0) { $0 + $1.monthly }
        let share = usdTotal / total
        guard share > InsightThresholds.usdShareThresholdPercent else { return [] }

        let percent = Int((share * 100).rounded())
        let body = "USD 订阅占 \(percent)%，汇率波动会影响月度支出。"
        return [
            Insight(
                severity: .info,
                icon: "dollarsign.arrow.circlepath",
                title: "USD 敞口",
                body: body,
                suggestion: nil
            )
        ]
    }
}
