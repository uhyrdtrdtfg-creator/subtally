import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Subscription.nextBillingDate, order: .forward) private var subs: [Subscription]

    @State private var showAdd = false
    @State private var editingSub: Subscription?

    private var monthly: Double {
        subs.reduce(0) { $0 + $1.mineMonthlyCostCNY(usdRate: settings.usdCnyRate) }
    }

    private var monthLabel: String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: Date())
        return "SUBSCRIPTIONS · \(monthName(c.month ?? 1)) \(c.year ?? 2026)"
    }

    private let sparkHeights: [CGFloat] = [0.78, 0.83, 0.89, 0.92, 0.95, 1.00, 0.97]

    private var upcoming: [Subscription] {
        subs.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var expiringTrials: [Subscription] {
        subs.filter { s in
            guard let d = s.daysUntilTrialEnd() else { return false }
            return d >= 0 && d <= 3
        }.sorted { ($0.daysUntilTrialEnd() ?? 99) < ($1.daysUntilTrialEnd() ?? 99) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TopBar(eyebrow: monthLabel, avatarText: avatarInitial(settings.userName))
                BigTitle(text: "本月")

                if subs.isEmpty {
                    EmptyStateView(
                        systemImage: "tray",
                        title: "还没有订阅",
                        message: "添加你的第一个订阅，App 会自动统计支出、提醒到期。",
                        actionTitle: "新建订阅"
                    ) { showAdd = true }
                    .padding(.top, 30)
                } else {
                    heroCard.padding(.horizontal, 24).padding(.top, 22)

                    if !expiringTrials.isEmpty {
                        trialBanner.padding(.horizontal, 24).padding(.top, 14)
                    }

                    SectionHead("即将到期", meta: "\(upcoming.count) ITEMS")

                    rowsList
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEditSubscriptionView() }
        .sheet(item: $editingSub) { sub in AddEditSubscriptionView(editing: sub) }
        .overlay(alignment: .bottomTrailing) {
            Button { showAdd = true } label: {
                ZStack {
                    Circle().fill(palette.ink)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(palette.bg)
                }
                .frame(width: 52, height: 52)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }

    private var trialBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("免费试用即将结束")
                    .font(AppFont.geist(13, weight: .semibold))
                Spacer()
                Text("\(expiringTrials.count) 个")
                    .font(AppFont.mono(11, weight: .medium))
                    .foregroundStyle(palette.amber)
            }
            .foregroundStyle(palette.amber)
            VStack(spacing: 6) {
                ForEach(expiringTrials) { s in
                    HStack(spacing: 10) {
                        BrandIcon(sub: s, size: 24)
                        Text(s.name).font(AppFont.geist(13, weight: .medium)).foregroundStyle(palette.ink)
                        Spacer()
                        let d = s.daysUntilTrialEnd() ?? 0
                        Text(d == 0 ? "今日结束" : "\(d) 天后结束")
                            .font(AppFont.geist(12, weight: .semibold))
                            .foregroundStyle(palette.amber)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.amberBg)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.amber.opacity(0.35), lineWidth: 1))
        )
    }

    private var heroCard: some View {
        let display = settings.defaultCurrency
        let rate = settings.usdCnyRate
        let displayMonthly = display == .usd ? monthly / max(rate, 0.01) : monthly
        let displayAnnual = displayMonthly * 12
        let deltaCny = monthly * 0.03
        let displayDelta = display == .usd ? deltaCny / max(rate, 0.01) : deltaCny

        return VStack(alignment: .leading, spacing: 12) {
            CardLabel(text: "总支出")
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(display.symbol)
                    .font(AppFont.heroCcy)
                    .foregroundStyle(palette.ink3)
                    .baselineOffset(18)
                Text("\(Int(displayMonthly.rounded()))")
                    .font(AppFont.heroBig)
                    .kerning(-1.4)
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
                Text("/月")
                    .font(AppFont.heroUnit)
                    .foregroundStyle(palette.ink3)
                    .padding(.leading, 4)
            }
            HStack(spacing: 6) {
                DeltaChip(text: "↑ \(display.symbol)\(Int(displayDelta.rounded()))", direction: .up)
                Text("较上月 · 年化 \(display.symbol)\(Fmt.thousandsInt(Int(displayAnnual.rounded())))")
                    .font(AppFont.geist(13))
                    .foregroundStyle(palette.ink3)
            }
            sparkline.padding(.top, 4)
        }
        .cardBackground()
    }

    private var sparkline: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(sparkHeights.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(i == 5 ? palette.green : palette.border)
                        .frame(height: max(4, geo.size.height * h))
                }
            }
        }
        .frame(height: 40)
    }

    private var rowsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(upcoming.enumerated()), id: \.element.persistentModelID) { idx, sub in
                Button { editingSub = sub } label: {
                    SubscriptionRow(sub: sub, showDivider: idx > 0)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("编辑") { editingSub = sub }
                    Button("删除", role: .destructive) { delete(sub) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(sub) } label: { Label("删除", systemImage: "trash") }
                }
            }
        }
    }

    @Environment(\.modelContext) private var context

    private func delete(_ sub: Subscription) {
        context.delete(sub)
        try? context.save()
    }

    private func avatarInitial(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.prefix(1)).uppercased()
    }

    private func monthName(_ m: Int) -> String {
        ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"][max(0, min(11, m - 1))]
    }
}
