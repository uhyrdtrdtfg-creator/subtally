import SwiftUI
import SwiftData

struct TrendsView: View {
    enum Range: Hashable { case twelve, four }

    @Environment(\.palette) private var palette
    @EnvironmentObject private var settings: AppSettings
    @Query private var subs: [Subscription]

    @State private var range: Range = .twelve
    @State private var selectedIdx: Int = 11

    private var monthly: Double {
        subs.reduce(0) { $0 + $1.mineMonthlyCostCNY(usdRate: settings.usdCnyRate) }
    }

    private var trend12: [(label: String, value: Int)] {
        let base = monthly
        let noise: [Double] = [0.86, 0.88, 0.84, 0.90, 0.93, 0.91, 0.95, 0.92, 0.96, 0.98, 1.03, 1.00]
        let now = Calendar(identifier: .gregorian).dateComponents([.month], from: Date()).month ?? 4
        return noise.enumerated().map { i, n in
            let m = ((now - 11 + i - 1 + 12 * 10) % 12) + 1
            return ("\(m)月", Int((base * n).rounded()))
        }
    }

    private var displayed: [(label: String, value: Int)] {
        range == .twelve ? trend12 : Array(trend12.suffix(4))
    }

    private var byCategory: [(cat: SubscriptionCategory, value: Int)] {
        var map: [SubscriptionCategory: Double] = [:]
        for s in subs {
            map[s.category, default: 0] += s.mineMonthlyCostCNY(usdRate: settings.usdCnyRate)
        }
        return map
            .map { ($0.key, Int($0.value.rounded())) }
            .sorted { $0.1 > $1.1 }
    }

    private var top5: [(sub: Subscription, monthly: Double)] {
        subs.map { ($0, $0.mineMonthlyCostCNY(usdRate: settings.usdCnyRate)) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TopBar(eyebrow: "TRENDS · LAST 12 MONTHS", avatarText: String(settings.userName.prefix(1)).uppercased())
                BigTitle(text: "趋势")

                if subs.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "还没有趋势可看",
                        message: "添加订阅后，这里会显示你的支出走势和分类占比。"
                    )
                    .padding(.top, 30)
                } else {
                    chartContent
                }
            }
        }
        .onChange(of: displayed.count) { _, _ in
            selectedIdx = min(selectedIdx, max(0, displayed.count - 1))
        }
    }

    private var chartContent: some View {
        VStack(spacing: 0) {
            PillBar(items: [(Range.twelve, "12 个月"), (Range.four, "近 4 月")], selection: $range)
                    .onChange(of: range) { _, new in
                        selectedIdx = new == .twelve ? 11 : 3
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)

                trendCard
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                kpiGrid
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                SectionHead("按分类", meta: "MONTHLY · CNY")
                categoryCard.padding(.horizontal, 24)

            SectionHead("Top 5 最贵", meta: "BY MONTHLY")
            top5List

            let insights = InsightsEngine.analyze(subs: subs, usdCnyRate: settings.usdCnyRate)
            if !insights.isEmpty {
                SectionHead("智能洞察", meta: "\(insights.count) ITEMS")
                InsightsView(insights: insights)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var trendCard: some View {
        let clampedIdx = min(selectedIdx, max(0, displayed.count - 1))
        let sel = displayed.isEmpty ? ("", 0) : displayed[clampedIdx]
        let prev = clampedIdx > 0 ? displayed[clampedIdx - 1] : nil
        let deltaAmount = prev.map { sel.1 - $0.1 } ?? 0
        let deltaDir: DeltaChip.Direction = {
            guard prev != nil else { return .flat }
            if deltaAmount > 0 { return .up }
            if deltaAmount < 0 { return .down }
            return .flat
        }()
        let maxVal = max(1, displayed.map { $0.1 }.max() ?? 1)
        let currentIdx = displayed.count - 1

        let display = settings.defaultCurrency
        let rate = settings.usdCnyRate

        return VStack(alignment: .leading, spacing: 12) {
            CardLabel(text: "\(sel.0) · 支出")
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(display.symbol).font(AppFont.heroCcy).foregroundStyle(palette.ink3).baselineOffset(18)
                Text(Fmt.displayInt(cnyAmount: Double(sel.1), in: display, usdCnyRate: rate).dropFirst().description)
                    .font(AppFont.heroBig).kerning(-1.4).monospacedDigit()
                    .foregroundStyle(palette.ink)
            }
            HStack(spacing: 6) {
                let absDelta = Double(abs(deltaAmount))
                let deltaSym = display.symbol
                let displayDeltaText: String = {
                    guard prev != nil else { return "—" }
                    if deltaAmount == 0 { return "0" }
                    let arrow = deltaAmount > 0 ? "↑" : "↓"
                    return "\(arrow) \(deltaSym)\(Fmt.displayInt(cnyAmount: absDelta, in: display, usdCnyRate: rate).dropFirst())"
                }()
                DeltaChip(text: displayDeltaText, direction: deltaDir)
                Text("\(clampedIdx > 0 ? "较上期" : "起点") · 年化 \(Fmt.displayInt(cnyAmount: Double(sel.1 * 12), in: display, usdCnyRate: rate))")
                    .font(AppFont.geist(13))
                    .foregroundStyle(palette.ink3)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(displayed.enumerated()), id: \.offset) { i, d in
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            let h = max(4, geo.size.height * CGFloat(d.1) / CGFloat(maxVal))
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor(i: i, current: currentIdx, selected: clampedIdx))
                                    .frame(height: h)
                                    .animation(.easeInOut(duration: 0.25), value: selectedIdx)
                            }
                        }
                        Text(d.0.replacingOccurrences(of: "月", with: ""))
                            .font(AppFont.mono(10))
                            .foregroundStyle(i == clampedIdx ? palette.ink : palette.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { selectedIdx = i } }
                }
            }
            .frame(height: 170)
            .padding(.top, 10)
        }
        .cardBackground()
    }

    private func barColor(i: Int, current: Int, selected: Int) -> Color {
        if i == selected { return palette.ink }
        if i == current { return palette.green }
        return palette.border
    }

    private var kpiGrid: some View {
        let display = settings.defaultCurrency
        let rate = settings.usdCnyRate
        return HStack(spacing: 1) {
            kpiTile(label: "月均", value: Fmt.displayInt(cnyAmount: monthly, in: display, usdCnyRate: rate), delta: "↑ 3.0%", deltaColor: palette.red)
            kpiTile(label: "年化", value: Fmt.displayInt(cnyAmount: monthly * 12, in: display, usdCnyRate: rate), delta: "12 个月", deltaColor: palette.ink3)
            kpiTile(label: "订阅数", value: "\(subs.count)", delta: "↓ 0 新增", deltaColor: palette.green)
        }
        .background(palette.border)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func kpiTile(label: String, value: String, delta: String, deltaColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AppFont.geist(10, weight: .medium))
                .kerning(1.4)
                .foregroundStyle(palette.ink3)
            Text(value)
                .font(AppFont.geist(22, weight: .bold))
                .kerning(-0.55)
                .monospacedDigit()
                .foregroundStyle(palette.ink)
            Text(delta)
                .font(AppFont.geist(11))
                .monospacedDigit()
                .foregroundStyle(deltaColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card)
    }

    private var categoryCard: some View {
        let total = max(1, byCategory.map { $0.value }.reduce(0, +))
        return VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(byCategory, id: \.cat) { item in
                        Rectangle()
                            .fill(item.cat.accentColor)
                            .frame(width: geo.size.width * CGFloat(item.value) / CGFloat(total))
                    }
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(spacing: 10) {
                ForEach(byCategory, id: \.cat) { item in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3).fill(item.cat.accentColor).frame(width: 10, height: 10)
                        Text(item.cat.displayName).font(AppFont.geist(13, weight: .medium)).foregroundStyle(palette.ink2)
                        Spacer()
                        Text("¥\(item.value)")
                            .font(AppFont.geist(13, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(palette.ink)
                        Text("\(Int(round(Double(item.value) * 100 / Double(total))))%")
                            .font(AppFont.mono(11))
                            .foregroundStyle(palette.ink3)
                    }
                }
            }
        }
        .cardBackground()
    }

    private var top5List: some View {
        let maxV = max(1, top5.map { $0.monthly }.max() ?? 1)
        return VStack(spacing: 0) {
            ForEach(Array(top5.enumerated()), id: \.element.sub.persistentModelID) { i, item in
                VStack(spacing: 0) {
                    if i > 0 {
                        Rectangle().fill(palette.border).frame(height: 1).padding(.horizontal, 24)
                    }
                    HStack(spacing: 12) {
                        Text(String(format: "%02d", i + 1))
                            .font(AppFont.mono(11, weight: .medium))
                            .foregroundStyle(palette.ink3)
                            .frame(width: 20, alignment: .leading)

                        BrandIcon(sub: item.sub, size: 28)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.sub.name).font(AppFont.geist(13, weight: .medium)).foregroundStyle(palette.ink)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2).fill(palette.border).frame(height: 4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(item.sub.category.accentColor)
                                        .frame(width: geo.size.width * CGFloat(item.monthly / maxV), height: 4)
                                }
                            }
                            .frame(height: 4)
                        }

                        Text("¥\(Int(item.monthly.rounded()))")
                            .font(AppFont.geist(14, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(palette.ink)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)
                }
            }
        }
    }
}
