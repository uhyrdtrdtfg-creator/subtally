import SwiftUI

struct SubscriptionRow: View {
    let sub: Subscription
    var showDivider: Bool = true

    @Environment(\.palette) private var palette

    private var days: Int { sub.daysUntilNext() }

    private var metaText: String {
        if sub.isFreeTrial, let trialDays = sub.daysUntilTrialEnd() {
            if trialDays < 0 { return "试用已结束 · \(sub.cycle.displayName)" }
            if trialDays == 0 { return "试用今日结束" }
            return "试用 \(trialDays) 天后结束"
        }
        return "\(Fmt.shortDate(sub.nextBillingDate)) · \(sub.cycle.displayName)"
    }

    private var daysLabelColor: Color {
        if days < 0 { return palette.ink3 }
        if days <= 3 { return palette.red }
        if days <= 7 { return palette.amber }
        return palette.ink3
    }

    private var daysWeight: Font.Weight {
        (days <= 7 && days >= 0) ? .semibold : .regular
    }

    var body: some View {
        VStack(spacing: 0) {
            if showDivider {
                Rectangle()
                    .fill(palette.border)
                    .frame(height: 1)
                    .padding(.leading, 68)
                    .padding(.trailing, 24)
            }
            HStack(spacing: 14) {
                BrandIcon(sub: sub)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(sub.name)
                            .font(AppFont.rowName)
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                        CategoryChip(category: sub.category)
                        if sub.isFreeTrial { TrialChip() }
                    }
                    Text(metaText)
                        .font(AppFont.rowMeta)
                        .foregroundStyle(palette.ink3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.money(sub.price, sub.currency))
                        .font(AppFont.rowPrice)
                        .monospacedDigit()
                        .foregroundStyle(palette.ink)
                    Text(Fmt.daysText(days))
                        .font(AppFont.geist(11, weight: daysWeight))
                        .monospacedDigit()
                        .foregroundStyle(daysLabelColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
        }
    }
}
