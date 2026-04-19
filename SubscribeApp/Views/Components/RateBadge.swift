import SwiftUI

struct RateBadge: View {
    let rate: Double
    let lastFetched: Date?
    let source: String
    let onRefresh: () async -> Void

    @State private var isRefreshing = false
    @Environment(\.palette) private var palette

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f
    }()

    private var rateText: String {
        String(format: "USD/CNY  %.2f", rate)
    }

    private var subtitleText: String {
        guard let lastFetched else {
            return "未更新 · 默认值"
        }
        let relative = Self.relativeFormatter.localizedString(for: lastFetched, relativeTo: Date())
        return "\(relative) · \(source)"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rateText)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.ink)
                Text(subtitleText)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.ink3)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            refreshButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private var refreshButton: some View {
        Button {
            guard !isRefreshing else { return }
            Task {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
        } label: {
            ZStack {
                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.ink3)
                }
            }
            .frame(width: 28, height: 28)
            .background(
                Circle().fill(palette.card)
            )
            .overlay(
                Circle().stroke(palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .accessibilityLabel("刷新汇率")
    }
}
