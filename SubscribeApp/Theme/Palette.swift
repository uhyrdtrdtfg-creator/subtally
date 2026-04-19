import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((v >> 16) & 0xFF) / 255.0
            g = Double((v >> 8) & 0xFF) / 255.0
            b = Double(v & 0xFF) / 255.0
            a = 1
        case 8:
            r = Double((v >> 24) & 0xFF) / 255.0
            g = Double((v >> 16) & 0xFF) / 255.0
            b = Double((v >> 8) & 0xFF) / 255.0
            a = Double(v & 0xFF) / 255.0
        default:
            r = 0.5; g = 0.5; b = 0.5; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct Palette {
    let bg: Color
    let card: Color
    let cardHi: Color
    let border: Color
    let ink: Color
    let ink2: Color
    let ink3: Color
    let green: Color
    let greenBg: Color
    let red: Color
    let redBg: Color
    let amber: Color
    let amberBg: Color
    let tabbarBg: Color

    static let dark = Palette(
        bg: Color(hex: "0C0C10"),
        card: Color(hex: "16161B"),
        cardHi: Color(hex: "1C1C23"),
        border: Color(hex: "24242C"),
        ink: Color(hex: "F6F5F2"),
        ink2: Color(hex: "B7B6AE"),
        ink3: Color(hex: "8A8A95"),
        green: Color(hex: "4A7C59"),
        greenBg: Color(hex: "4A7C59").opacity(0.18),
        red: Color(hex: "E56C56"),
        redBg: Color(hex: "E56C56").opacity(0.15),
        amber: Color(hex: "D4A848"),
        amberBg: Color(hex: "D4A848").opacity(0.14),
        tabbarBg: Color(hex: "0C0C10").opacity(0.92)
    )

    static let light = Palette(
        bg: Color(hex: "F7F6F1"),
        card: Color(hex: "FFFFFF"),
        cardHi: Color(hex: "FDFBF3"),
        border: Color(hex: "EAE7DD"),
        ink: Color(hex: "0C0C10"),
        ink2: Color(hex: "55534C"),
        ink3: Color(hex: "8A8A7A"),
        green: Color(hex: "2A5F3E"),
        greenBg: Color(hex: "2A5F3E").opacity(0.12),
        red: Color(hex: "C14A33"),
        redBg: Color(hex: "C14A33").opacity(0.12),
        amber: Color(hex: "A08235"),
        amberBg: Color(hex: "A08235").opacity(0.14),
        tabbarBg: Color(hex: "F7F6F1").opacity(0.92)
    )
}

struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .dark
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension SubscriptionCategory {
    var accentColor: Color {
        switch self {
        case .video: return Color(hex: "E56C56")
        case .music: return Color(hex: "4A7C59")
        case .cloud: return Color(hex: "6B8AB8")
        case .ai:    return Color(hex: "D4A848")
        case .work:  return Color(hex: "9B7EBD")
        }
    }
}
