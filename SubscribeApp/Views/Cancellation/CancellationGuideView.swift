import SwiftUI

/// 退订指引 Sheet — 只读
struct CancellationGuideView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let guide: CancellationGuide

    init(guide: CancellationGuide) {
        self.guide = guide
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard
                    primaryCTA
                    stepsSection
                    if !guide.warnings.isEmpty {
                        warningsSection
                    }
                    otherChoicesSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("退订 \(guide.serviceName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(palette.ink)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(guide.serviceName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.ink)
            Text("按以下步骤即可关闭自动续费,避免下个周期被扣款。")
                .font(.subheadline)
                .foregroundStyle(palette.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.cardHi)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var primaryCTA: some View {
        if let webURL = guide.webURL {
            ctaButton(
                title: "前往退订页面",
                icon: "safari",
                url: webURL
            )
        } else if let deeplink = guide.appDeeplink {
            ctaButton(
                title: "打开 \(guide.serviceName) App",
                icon: "iphone.gen3",
                url: deeplink
            )
        } else {
            HStack {
                Image(systemName: "info.circle")
                Text("此服务暂无网页退订入口,请在官方 App 内自行操作")
                    .font(.subheadline)
            }
            .foregroundStyle(palette.ink2)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.card)
            )
        }
    }

    private func ctaButton(title: String, icon: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).font(.body.weight(.semibold))
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.8)
            }
            .foregroundStyle(palette.bg)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.ink)
            )
        }
        .buttonStyle(.plain)
    }

    private var stepsSection: some View {
        section(title: "步骤") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: numberSymbol(for: index + 1))
                            .font(.title3)
                            .foregroundStyle(palette.ink)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var warningsSection: some View {
        section(title: "注意") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(guide.warnings.enumerated()), id: \.offset) { _, warning in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(palette.amber)
                        Text(warning)
                            .font(.subheadline)
                            .foregroundStyle(palette.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var otherChoicesSection: some View {
        section(title: "其他选择") {
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("找客服(邮件/电话)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.ink)
                        Text("如线上入口找不到,可联系官方客服协助退订或退款")
                            .font(.caption)
                            .foregroundStyle(palette.ink3)
                    }
                } icon: {
                    Image(systemName: "headphones")
                        .foregroundStyle(palette.ink2)
                }
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Store 退订")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.ink)
                        Text("Apple ID 续费的订阅一律到「设置 > Apple ID > 订阅」操作")
                            .font(.caption)
                            .foregroundStyle(palette.ink3)
                    }
                } icon: {
                    Image(systemName: "applelogo")
                        .foregroundStyle(palette.ink2)
                }
            }
        }
    }

    // MARK: - Helpers

    private func numberSymbol(for index: Int) -> String {
        switch index {
        case 1...50: return "\(index).circle.fill"
        default: return "circle.fill"
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.ink3)
                .textCase(.uppercase)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(palette.border, lineWidth: 1)
                        )
                )
        }
    }
}

#Preview {
    CancellationGuideView(guide: CancellationGuides.all.first!)
        .environment(\.palette, .dark)
}
