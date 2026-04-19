import SwiftUI

struct InsightsView: View {
    let insights: [Insight]

    init(insights: [Insight]) {
        self.insights = insights
    }

    var body: some View {
        if insights.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

private struct InsightCard: View {
    let insight: Insight
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: insight.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 22, height: 22)
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.ink)
                Spacer(minLength: 0)
            }

            Text(insight.body)
                .font(.system(size: 13))
                .foregroundStyle(palette.ink2)
                .fixedSize(horizontal: false, vertical: true)

            if let suggestion = insight.suggestion {
                HStack(spacing: 6) {
                    Text("💡 \(suggestion)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.ink2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(suggestionBg)
                        )
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(palette.border, lineWidth: 1)
                )
        )
    }

    private var iconColor: Color {
        switch insight.severity {
        case .info: return palette.ink2
        case .warning: return palette.amber
        case .alert: return palette.red
        }
    }

    private var suggestionBg: Color {
        switch insight.severity {
        case .info: return palette.greenBg
        case .warning: return palette.amberBg
        case .alert: return palette.redBg
        }
    }
}
