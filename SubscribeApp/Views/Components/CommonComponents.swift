import SwiftUI

struct CardBackground: ViewModifier {
    @Environment(\.palette) private var palette
    var padding: CGFloat = 22
    var corner: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(palette.border, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func cardBackground(padding: CGFloat = 22, corner: CGFloat = 18) -> some View {
        modifier(CardBackground(padding: padding, corner: corner))
    }
}

struct CardLabel: View {
    let text: String
    @Environment(\.palette) private var palette
    var body: some View {
        Text(text.uppercased())
            .font(AppFont.cardLabel)
            .kerning(1.6)
            .foregroundStyle(palette.ink3)
    }
}

struct EyebrowText: View {
    let text: String
    @Environment(\.palette) private var palette
    var body: some View {
        Text(text.uppercased())
            .font(AppFont.eyebrow)
            .kerning(1.8)
            .foregroundStyle(palette.ink3)
    }
}

struct SectionHead: View {
    let title: String
    let meta: String?
    @Environment(\.palette) private var palette

    init(_ title: String, meta: String? = nil) {
        self.title = title
        self.meta = meta
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(AppFont.sectionTitle).foregroundStyle(palette.ink)
            Spacer()
            if let meta {
                Text(meta.uppercased())
                    .font(AppFont.cardLabel)
                    .kerning(1.6)
                    .foregroundStyle(palette.ink3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 10)
    }
}

struct TopBar: View {
    let eyebrow: String
    let avatarText: String
    var onAvatarTap: (() -> Void)? = nil

    @Environment(\.palette) private var palette

    var body: some View {
        HStack {
            EyebrowText(text: eyebrow)
            Spacer()
            Button(action: { onAvatarTap?() }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "3A5A40"), Color(hex: "588157")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    Text(avatarText)
                        .font(AppFont.geist(13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
}

struct BigTitle: View {
    let text: String
    @Environment(\.palette) private var palette
    var body: some View {
        Text(text)
            .font(AppFont.bigTitle)
            .kerning(-0.9)
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 6)
    }
}

struct CategoryChip: View {
    let category: SubscriptionCategory
    @Environment(\.palette) private var palette

    var body: some View {
        Text(category.rawValue)
            .font(AppFont.rowChip)
            .kerning(0.6)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(palette.cardHi)
            .foregroundStyle(palette.ink3)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

struct TrialChip: View {
    @Environment(\.palette) private var palette
    var body: some View {
        Text("TRIAL")
            .font(AppFont.rowChip)
            .kerning(0.6)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(palette.amberBg)
            .foregroundStyle(palette.amber)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

struct PillBar<T: Hashable>: View {
    let items: [(T, String)]
    @Binding var selection: T
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = item.0 }
                } label: {
                    Text(item.1)
                        .font(AppFont.geist(12, weight: .medium))
                        .foregroundStyle(selection == item.0 ? palette.bg : palette.ink3)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule().fill(selection == item.0 ? palette.ink : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(palette.card)
                .overlay(Capsule().strokeBorder(palette.border, lineWidth: 1))
        )
    }
}

struct DeltaChip: View {
    let text: String
    let direction: Direction

    enum Direction { case up, down, flat }

    @Environment(\.palette) private var palette

    var body: some View {
        Text(text)
            .font(AppFont.geist(12, weight: .semibold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var bg: Color {
        switch direction {
        case .up: return palette.redBg
        case .down: return palette.greenBg
        case .flat: return palette.cardHi
        }
    }
    private var fg: Color {
        switch direction {
        case .up: return palette.red
        case .down: return palette.green
        case .flat: return palette.ink3
        }
    }
}
