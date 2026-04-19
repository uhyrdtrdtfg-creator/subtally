import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(palette.ink3)
            VStack(spacing: 6) {
                Text(title)
                    .font(AppFont.geist(16, weight: .semibold))
                    .foregroundStyle(palette.ink)
                Text(message)
                    .font(AppFont.geist(13))
                    .foregroundStyle(palette.ink3)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.geist(13, weight: .semibold))
                        .foregroundStyle(palette.bg)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(palette.ink))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}
