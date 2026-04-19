import SwiftUI
import SwiftData
import Charts

struct PriceHistoryView: View {
    let subID: String
    let subName: String

    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @Query private var changes: [PriceChange]

    init(subID: String, subName: String) {
        self.subID = subID
        self.subName = subName
        let predicate = #Predicate<PriceChange> { $0.subID == subID }
        _changes = Query(
            filter: predicate,
            sort: [SortDescriptor(\PriceChange.changedAt, order: .forward)]
        )
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var latest: PriceChange? { changes.last }

    private func color(for direction: PriceChange.Direction) -> Color {
        switch direction {
        case .up: return palette.red
        case .down: return palette.green
        case .flat: return palette.ink2
        }
    }

    private func arrow(for direction: PriceChange.Direction) -> String {
        switch direction {
        case .up: return "↑"
        case .down: return "↓"
        case .flat: return "→"
        }
    }

    private func priceText(_ amount: Double, currency: CurrencyCode) -> String {
        "\(currency.symbol)\(formatted(amount))"
    }

    private func formatted(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.bg.ignoresSafeArea()

                if changes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            chartCard
                            historyList
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(subName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .foregroundColor(palette.ink)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(palette.ink3)
            Text("还没有价格变动记录")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(palette.ink2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryCard: some View {
        Group {
            if let last = latest {
                let dir = last.direction
                let tint = color(for: dir)
                let delta = last.newPrice - last.oldPrice
                let absDelta = abs(delta)
                let pct = last.deltaPercent
                let signedPct = String(format: "%+.1f%%", pct)
                let dateStr = Self.dayFormatter.string(from: last.changedAt)

                VStack(alignment: .leading, spacing: 8) {
                    Text("最近一次变动")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.ink3)
                        .tracking(0.6)
                    HStack(spacing: 8) {
                        Text(arrow(for: dir))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(tint)
                        Text("\(last.currency.symbol)\(formatted(absDelta))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(palette.ink)
                        Text("(\(signedPct))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(tint)
                    }
                    Text("自 \(dateStr)")
                        .font(.system(size: 13))
                        .foregroundColor(palette.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(palette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("价格走势")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.ink3)
                .tracking(0.6)

            Chart {
                ForEach(changes, id: \.id) { change in
                    LineMark(
                        x: .value("时间", change.changedAt),
                        y: .value("价格", change.newPrice)
                    )
                    .foregroundStyle(palette.ink)
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("时间", change.changedAt),
                        y: .value("价格", change.newPrice)
                    )
                    .foregroundStyle(color(for: change.direction))
                    .symbolSize(60)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(palette.border)
                    AxisValueLabel().foregroundStyle(palette.ink3)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(palette.border)
                    AxisValueLabel().foregroundStyle(palette.ink3)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全部记录")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.ink3)
                .tracking(0.6)

            VStack(spacing: 0) {
                ForEach(Array(changes.reversed().enumerated()), id: \.element.id) { idx, change in
                    rowView(change)
                    if idx < changes.count - 1 {
                        Divider().background(palette.border)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
        }
    }

    private func rowView(_ change: PriceChange) -> some View {
        let dir = change.direction
        let tint = color(for: dir)
        let dateStr = Self.dayFormatter.string(from: change.changedAt)
        let delta = change.newPrice - change.oldPrice
        let absDelta = abs(delta)

        return HStack(spacing: 12) {
            Text(dateStr)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.ink2)
                .frame(width: 92, alignment: .leading)

            HStack(spacing: 6) {
                Text("→ \(priceText(change.newPrice, currency: change.currency))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.ink)
                Text("\(arrow(for: dir))\(change.currency.symbol)\(formatted(absDelta))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(dir == .up ? palette.redBg : (dir == .down ? palette.greenBg : palette.cardHi))
                    )
                Text("from \(priceText(change.oldPrice, currency: change.currency))")
                    .font(.system(size: 12))
                    .foregroundColor(palette.ink3)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
