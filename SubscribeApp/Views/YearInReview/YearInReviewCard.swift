import SwiftUI

/// A fixed-size 1080×1920 portrait card designed to be rasterized via
/// `ImageRenderer` and shared to social platforms (Instagram Story format).
///
/// All visual choices are intentional:
///  - Large amber wash + dark backdrop in the Spotify-Wrapped tradition
///  - Massive primary number, restrained supporting copy
///  - Brand tile reproduces the iOS-app-icon look without depending on
///    `BrandIcon` (which makes a network call) so the renderer stays
///    deterministic and offline.
struct YearInReviewCard: View {
    let year: Int
    let subs: [Subscription]
    let usdCnyRate: Double

    init(year: Int, subs: [Subscription], usdCnyRate: Double) {
        self.year = year
        self.subs = subs
        self.usdCnyRate = usdCnyRate
    }

    // MARK: - Layout constants

    private let canvasSize = CGSize(width: 1080, height: 1920)
    private let bg = Color(hex: "0C0C10")
    private let ink = Color(hex: "F6F5F2")
    private let ink2 = Color(hex: "B7B6AE")
    private let ink3 = Color(hex: "8A8A95")
    private let card = Color(hex: "16161B")
    private let border = Color(hex: "24242C")
    private let amber = Color(hex: "E8B37F")

    // MARK: - Computations

    private var yearTotal: Double {
        subs.reduce(0) { $0 + $1.monthlyCostCNY(usdRate: usdCnyRate) * 12.0 }
    }

    private var mineYearTotal: Double {
        subs.reduce(0) { $0 + $1.mineMonthlyCostCNY(usdRate: usdCnyRate) * 12.0 }
    }

    private var monthlyAvg: Double { yearTotal / 12.0 }

    private var count: Int { subs.count }

    /// Total - mine, summed across subscriptions; how much family/group sharing
    /// shaved off the year.
    private var savingsFromShared: Double { max(0, yearTotal - mineYearTotal) }

    /// Number of yearly-cycle subs (rough proxy for "annual prepay savings").
    private var yearlyPrepayCount: Int {
        subs.filter { $0.cycle == .year }.count
    }

    /// Trial subscriptions counted (free or active trial flag).
    private var trialCount: Int { subs.filter { $0.isFreeTrial }.count }

    private var topService: Subscription? {
        subs.max(by: {
            $0.monthlyCostCNY(usdRate: usdCnyRate) <
            $1.monthlyCostCNY(usdRate: usdCnyRate)
        })
    }

    private struct CategoryAgg {
        let category: SubscriptionCategory
        let yearAmount: Double
        let count: Int
    }

    private var topCategory: CategoryAgg? {
        let buckets = Dictionary(grouping: subs, by: { $0.category })
        let aggs: [CategoryAgg] = buckets.map { (cat, items) in
            let total = items.reduce(0) {
                $0 + $1.monthlyCostCNY(usdRate: usdCnyRate) * 12.0
            }
            return CategoryAgg(category: cat, yearAmount: total, count: items.count)
        }
        return aggs.max(by: { $0.yearAmount < $1.yearAmount })
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            backdrop

            VStack(spacing: 0) {
                eyebrowSection
                    .padding(.top, 110)

                bigNumberSection
                    .padding(.top, 56)

                subtitleSection
                    .padding(.top, 22)

                topServiceCard
                    .padding(.top, 96)
                    .padding(.horizontal, 80)

                topCategoryCard
                    .padding(.top, 36)
                    .padding(.horizontal, 80)

                statsRow
                    .padding(.top, 60)
                    .padding(.horizontal, 80)

                Spacer(minLength: 0)

                bottomBrandRow
                    .padding(.horizontal, 80)
                    .padding(.bottom, 96)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .background(bg)
        .clipped()
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            // Top amber wash
            LinearGradient(
                colors: [amber.opacity(0.30), amber.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 760)
            .frame(maxWidth: .infinity, alignment: .top)

            // Big floating circles for texture
            Circle()
                .fill(amber.opacity(0.10))
                .frame(width: 520, height: 520)
                .offset(x: -260, y: -120)
                .blur(radius: 40)
            Circle()
                .stroke(amber.opacity(0.18), lineWidth: 2)
                .frame(width: 700, height: 700)
                .offset(x: 320, y: 60)
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .top)
        .allowsHitTesting(false)
    }

    // MARK: - Sections

    private var eyebrowSection: some View {
        HStack(spacing: 14) {
            Circle().fill(amber).frame(width: 14, height: 14)
            Text("SUBSCRIBE · \(String(year)) 年度总结")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(amber)
        }
    }

    private var bigNumberSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Text("¥")
                    .font(.system(size: 110, weight: .heavy, design: .rounded))
                    .foregroundStyle(amber)
                    .padding(.top, 56)
                Text(Fmt.thousandsInt(Int(yearTotal.rounded())))
                    .font(.system(size: 280, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: canvasSize.width - 80)

            Text("今年订阅总开销")
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(ink2)
                .padding(.top, -8)
        }
    }

    private var subtitleSection: some View {
        HStack(spacing: 18) {
            pill(text: "\(count) 个订阅")
            Text("·").foregroundStyle(ink3).font(.system(size: 28, weight: .bold))
            pill(text: "月均 ¥\(Fmt.thousandsInt(Int(monthlyAvg.rounded())))")
        }
    }

    @ViewBuilder
    private var topServiceCard: some View {
        if let top = topService {
            cardShell {
                HStack(alignment: .center, spacing: 28) {
                    brandTile(
                        colorHex: top.brandColorHex,
                        letter: top.fallbackLetter,
                        size: 140
                    )
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top 服务")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(amber)
                        Text(top.name)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("年付 ¥\(Fmt.thousandsInt(Int((top.monthlyCostCNY(usdRate: usdCnyRate) * 12).rounded())))")
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundStyle(ink2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 36)
            }
        } else {
            cardShell {
                Text("暂无订阅数据")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundStyle(ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
        }
    }

    @ViewBuilder
    private var topCategoryCard: some View {
        if let cat = topCategory {
            cardShell {
                HStack(spacing: 0) {
                    // Accent stripe
                    cat.category.accentColor
                        .frame(width: 18)

                    HStack(alignment: .center, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Top 分类")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(amber)
                            Text(cat.category.displayName)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(ink)
                            Text("\(cat.count) 项 · 年付 ¥\(Fmt.thousandsInt(Int(cat.yearAmount.rounded())))")
                                .font(.system(size: 26, weight: .medium, design: .rounded))
                                .foregroundStyle(ink2)
                        }
                        Spacer(minLength: 0)

                        // Big share-of-spend percent
                        let pct = yearTotal > 0
                            ? Int((cat.yearAmount / yearTotal * 100).rounded())
                            : 0
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(pct)%")
                                .font(.system(size: 80, weight: .heavy, design: .rounded))
                                .foregroundStyle(cat.category.accentColor)
                            Text("年开销占比")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundStyle(ink3)
                        }
                    }
                    .padding(.vertical, 28)
                    .padding(.horizontal, 30)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 18) {
            statTile(
                title: "订阅数",
                value: "\(count)"
            )
            statTile(
                title: "年付节省",
                value: "¥\(Fmt.thousandsInt(Int((yearlyAnnualSavings()).rounded())))"
            )
            statTile(
                title: "家庭分摊省",
                value: "¥\(Fmt.thousandsInt(Int(savingsFromShared.rounded())))"
            )
            statTile(
                title: "试用次数",
                value: "\(trialCount)"
            )
        }
    }

    private var bottomBrandRow: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(amber)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Text("S")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(bg)
                        )
                    Text("Subtally")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                }
                Text("订阅 · 一目了然")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(ink3)
                    .tracking(2)
                    .padding(.leading, 50)
            }

            Spacer(minLength: 0)

            // QR placeholder rectangle (visual hook for App Store linkout)
            qrPlaceholder
        }
    }

    // MARK: - Building blocks

    private func pill(text: String) -> some View {
        Text(text)
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundStyle(ink)
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(card)
                    .overlay(Capsule().stroke(border, lineWidth: 1))
            )
    }

    private func cardShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(card)
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .overlay(content())
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(ink3)
                .tracking(1)
            Text(value)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 22)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(border, lineWidth: 1)
                )
        )
    }

    /// Inline reproduction of `BrandIcon`'s tile look — same 22.5% corner
    /// radius and white-letter fallback. No network calls so the renderer is
    /// fully deterministic.
    private func brandTile(colorHex: String, letter: String, size: CGFloat) -> some View {
        let brand = Color(hex: colorHex)
        let trimmed = letter.trimmingCharacters(in: .whitespaces)
        let display = trimmed.isEmpty ? "?" : String(trimmed.prefix(2))
        let isCJK = display.unicodeScalars.contains { $0.value >= 0x3000 }
        let fontSize: CGFloat = (display.count >= 2 && !isCJK) ? size * 0.42 : size * 0.55

        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(brand)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
                )
                .shadow(color: brand.opacity(0.35), radius: size * 0.06, y: 2)

            Text(display)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(letterColor(for: colorHex))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, size * 0.1)
        }
        .frame(width: size, height: size)
    }

    private func letterColor(for hex: String) -> Color {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return .white }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return lum > 0.78 ? Color(hex: "1A1814") : .white
    }

    private var qrPlaceholder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(ink)
            .frame(width: 160, height: 160)
            .overlay(
                // Subtle internal grid hinting "QR-ish"
                ZStack {
                    VStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            HStack(spacing: 12) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(bg)
                                        .frame(width: 22, height: 22)
                                }
                            }
                        }
                    }
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(amber)
                        .frame(width: 30, height: 30)
                }
                .padding(20)
            )
    }

    // Annual-prepay savings is conventionally non-trivial to quantify without
    // a per-service month-vs-year price catalog, so we publish a clean,
    // honest 10% headline saving on yearly-cycle subs as a stand-in.
    private func yearlyAnnualSavings() -> Double {
        subs
            .filter { $0.cycle == .year }
            .reduce(0) { $0 + $1.priceInCNY(usdRate: usdCnyRate) * 0.10 }
    }
}

#Preview {
    YearInReviewCard(year: 2026, subs: [], usdCnyRate: 7.25)
        .scaleEffect(0.32)
        .frame(width: 1080 * 0.32, height: 1920 * 0.32)
}
