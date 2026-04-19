import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "creditcard.viewfinder")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(palette.ink)
                Text("管好你的订阅")
                    .font(AppFont.geist(28, weight: .bold))
                    .kerning(-0.7)
                Text("追踪每一笔订阅、提醒到期、统计支出。\n所有数据都安全存在你的 iCloud。")
                    .font(AppFont.geist(14))
                    .foregroundStyle(palette.ink3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    SampleData.ensureSeeded(context: context)
                    finish()
                } label: {
                    Text("加载示例数据看看效果")
                        .font(AppFont.geist(15, weight: .semibold))
                        .foregroundStyle(palette.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(palette.ink))
                }
                .buttonStyle(.plain)

                Button {
                    finish()
                } label: {
                    Text("从空开始")
                        .font(AppFont.geist(15, weight: .medium))
                        .foregroundStyle(palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().strokeBorder(palette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Text("可以随时在「我的 → 数据」里清空或重置")
                    .font(AppFont.geist(11))
                    .foregroundStyle(palette.ink3)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.bg.ignoresSafeArea())
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        onComplete()
        dismiss()
    }
}
