import SwiftUI

/// iOS-app-icon style brand mark.
///
/// Rendering strategy:
/// 1. Always paints a brand-color rounded square tile.
/// 2. Tries to overlay the actual brand mark from simpleicons, forcing the
///    icon color to white via `cdn.simpleicons.org/{slug}/FFFFFF`. The SVG is
///    rasterized to PNG by `images.weserv.nl` so iOS's `AsyncImage` (which
///    can't decode SVG) can render it.
/// 3. If the slug is missing or loading fails, falls back to a white letter on
///    the tile — still looks like an iOS app icon.
struct BrandIcon: View {
    let slug: String
    let colorHex: String
    let fallbackLetter: String
    var size: CGFloat = 38

    @State private var failed = false

    private var brandColor: Color { Color(hex: colorHex) }

    private var iconURL: URL? {
        let cleaned = slug.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        // Force white SVG, rasterize to PNG via weserv proxy.
        let pixel = max(64, Int(size * 3))
        return URL(string: "https://images.weserv.nl/?url=cdn.simpleicons.org/\(cleaned)/FFFFFF&output=png&w=\(pixel)&h=\(pixel)")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(brandColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
                )
                .shadow(color: brandColor.opacity(0.25), radius: size * 0.05, y: 1)

            if let url = iconURL, !failed {
                AsyncImage(url: url, transaction: .init(animation: .easeIn(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit().padding(size * 0.20)
                    case .failure:
                        letterFallback.onAppear { failed = true }
                    case .empty:
                        letterFallback
                    @unknown default:
                        letterFallback
                    }
                }
            } else {
                letterFallback
            }
        }
        .frame(width: size, height: size)
    }

    private var letterFallback: some View {
        Text(effectiveLetter())
            .font(.system(size: fontSize(for: effectiveLetter()), weight: .bold))
            .foregroundStyle(textColorForBrand())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, size * 0.1)
    }

    private func effectiveLetter() -> String {
        let l = fallbackLetter.trimmingCharacters(in: .whitespaces)
        return l.isEmpty ? "?" : String(l.prefix(2))
    }

    private func fontSize(for letter: String) -> CGFloat {
        let isCJK = letter.unicodeScalars.contains { $0.value >= 0x3000 }
        if letter.count >= 2 && !isCJK { return size * 0.42 }
        return size * 0.55
    }

    private func textColorForBrand() -> Color {
        var s = colorHex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return .white }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum > 0.78 ? Color(hex: "1A1814") : .white
    }
}

extension BrandIcon {
    init(sub: Subscription, size: CGFloat = 38) {
        self.init(slug: sub.slug, colorHex: sub.brandColorHex, fallbackLetter: sub.fallbackLetter, size: size)
    }
}
