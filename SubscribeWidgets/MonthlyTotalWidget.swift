import WidgetKit
import SwiftUI

struct MonthlyTotalWidget: Widget {
    let kind = "MonthlyTotalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubProvider()) { entry in
            MonthlyTotalView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("本月支出")
        .description("一眼看见本月订阅总额与订阅数。")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

struct MonthlyTotalView: View {
    @Environment(\.widgetFamily) var family
    let entry: SubEntry

    private var expiringTrialCount: Int {
        entry.items.filter {
            guard let d = $0.trialDays else { return false }
            return d >= 0 && d <= 3
        }.count
    }

    var body: some View {
        switch family {
        case .systemSmall:
            small
        case .accessoryCircular:
            circular
        case .accessoryInline:
            inline
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("本月").font(.system(size: 11, weight: .semibold)).kerning(1.2).foregroundStyle(.secondary)
            Text("¥\(Int(entry.monthlyCNY.rounded()))")
                .font(.system(size: 32, weight: .bold))
                .monospacedDigit()
            Text("共 \(entry.items.count) 个订阅")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if expiringTrialCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(expiringTrialCount) 个试用要结束")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.orange)
            }
        }
    }

    private var circular: some View {
        VStack(spacing: 0) {
            Text("¥").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            Text("\(Int(entry.monthlyCNY.rounded()))")
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
        }
    }

    private var inline: some View {
        Text("本月订阅 ¥\(Int(entry.monthlyCNY.rounded())) · \(entry.items.count) 项")
    }
}
