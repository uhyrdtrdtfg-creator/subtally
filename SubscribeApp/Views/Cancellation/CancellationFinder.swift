import SwiftUI

/// 在订阅详情中嵌入的「如何退订」按钮 / 占位
/// 根据 `Subscription` 的 slug + name 自动匹配指引库
struct CancellationButton: View {
    @Environment(\.palette) private var palette
    @State private var isPresentingGuide = false

    let sub: Subscription

    init(sub: Subscription) {
        self.sub = sub
    }

    private var matchedGuide: CancellationGuide? {
        CancellationGuides.find(slug: sub.slug, name: sub.name)
    }

    var body: some View {
        Group {
            if let guide = matchedGuide {
                foundButton(guide: guide)
            } else {
                missingHint
            }
        }
        .sheet(isPresented: $isPresentingGuide) {
            if let guide = matchedGuide {
                CancellationGuideView(guide: guide)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - States

    private func foundButton(guide: CancellationGuide) -> some View {
        Button {
            isPresentingGuide = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(palette.cardHi)
                    Text("\u{1F4BC}")
                        .font(.title3)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("如何退订 \(guide.serviceName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text("查看官方退订步骤与注意事项")
                        .font(.caption)
                        .foregroundStyle(palette.ink3)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.ink3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var missingHint: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "envelope.badge")
                .font(.title3)
                .foregroundStyle(palette.ink3)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(palette.cardHi)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("暂无 \(sub.name) 退订指引")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)
                Text("你可以告诉我们 hi@subscribe.app,我们会尽快补上。")
                    .font(.caption)
                    .foregroundStyle(palette.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
        )
    }
}
