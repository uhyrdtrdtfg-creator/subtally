import SwiftUI

enum AppFont {
    static func geist(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let eyebrow = geist(11, weight: .medium).leading(.tight)
    static let cardLabel = geist(11, weight: .medium)
    static let rowName = geist(15, weight: .medium)
    static let rowChip = geist(10, weight: .semibold)
    static let rowMeta = geist(12)
    static let rowPrice = geist(17, weight: .semibold)
    static let rowDays = geist(11, weight: .semibold)
    static let sectionTitle = geist(18, weight: .semibold)
    static let bigTitle = geist(32, weight: .bold)
    static let heroBig = geist(48, weight: .bold)
    static let heroCcy = geist(22, weight: .medium)
    static let heroUnit = geist(18, weight: .medium)
}

struct TabularNumModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.monospacedDigit()
    }
}

extension View {
    func tnum() -> some View { modifier(TabularNumModifier()) }
}
