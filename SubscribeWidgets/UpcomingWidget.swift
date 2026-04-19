import WidgetKit
import SwiftUI

struct UpcomingWidget: Widget {
    let kind = "UpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubProvider()) { entry in
            UpcomingWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("即将到期")
        .description("最近要扣款的订阅，随时一眼可见。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct UpcomingWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SubEntry

    private var upcoming: [SubSnapshot] {
        entry.items.filter { $0.days >= 0 }.sorted { $0.days < $1.days }
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCircular:
            circularView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NEXT").font(.system(size: 10, weight: .semibold)).kerning(1.4).foregroundStyle(.secondary)
            if let n = upcoming.first {
                HStack(spacing: 8) {
                    WidgetBrandTile(letter: n.letter, name: n.name, colorHex: n.colorHex, size: 28)
                    Text(n.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(moneyText(n.price, n.currency))
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
                Text(daysText(n.days))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(daysColor(n.days))
            } else {
                Text("暂无订阅").font(.system(size: 14))
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("UPCOMING").font(.system(size: 10, weight: .semibold)).kerning(1.4).foregroundStyle(.secondary)
                Spacer()
                Text("¥\(Int(entry.monthlyCNY.rounded()))/月")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                ForEach(upcoming.prefix(3)) { s in
                    HStack(spacing: 8) {
                        WidgetBrandTile(letter: s.letter, name: s.name, colorHex: s.colorHex, size: 22)
                        Text(s.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                        Spacer()
                        Text(moneyText(s.price, s.currency))
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                        Text(daysText(s.days))
                            .font(.system(size: 10, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(daysColor(s.days))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let n = upcoming.first {
                Text(n.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                HStack(spacing: 6) {
                    Text(moneyText(n.price, n.currency)).font(.system(size: 12, weight: .semibold)).monospacedDigit()
                    Text(daysText(n.days)).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Text("¥\(Int(entry.monthlyCNY.rounded()))/月 · 本月")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                Text("订阅").font(.headline)
                Text("暂无").font(.caption)
            }
        }
    }

    private var circularView: some View {
        ZStack {
            Circle().stroke(lineWidth: 2).opacity(0.3)
            if let n = upcoming.first {
                VStack(spacing: 0) {
                    Text("\(n.days)").font(.system(size: 16, weight: .bold)).monospacedDigit()
                    Text("d").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "checkmark")
            }
        }
    }

    private func moneyText(_ v: Double, _ c: CurrencyCode) -> String {
        let sym = c.symbol
        return abs(v - v.rounded()) < 0.01 ? sym + "\(Int(v.rounded()))" : sym + String(format: "%.2f", v)
    }

    private func daysText(_ d: Int) -> String {
        if d == 0 { return "今天" }
        return "in \(d)d"
    }

    private func daysColor(_ d: Int) -> Color {
        if d <= 3 { return .red }
        if d <= 7 { return .orange }
        return .secondary
    }
}

extension Color {
    init(widgetHex hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255.0,
                  green: Double((v >> 8) & 0xFF) / 255.0,
                  blue: Double(v & 0xFF) / 255.0,
                  opacity: 1)
    }
}

/// iOS-app-icon-style brand tile for widgets.
struct WidgetBrandTile: View {
    let letter: String
    let name: String
    let colorHex: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(Color(widgetHex: colorHex))
            Text(effectiveLetter)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, size * 0.1)
        }
        .frame(width: size, height: size)
    }

    private var effectiveLetter: String {
        let l = letter.trimmingCharacters(in: .whitespaces)
        if !l.isEmpty { return String(l.prefix(2)) }
        return String(name.prefix(1)).isEmpty ? "?" : String(name.prefix(1))
    }

    private var textColor: Color {
        var s = colorHex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return .white }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum > 0.78 ? .black : .white
    }
}
