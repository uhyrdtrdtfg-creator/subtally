import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity + Dynamic Island for free-trial expiry countdown.
///
/// Visual palette:
///   bg    #0C0C10
///   ink   #F6F5F2
///   amber #D4A848
struct TrialLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrialActivityAttributes.self) { context in
            // Lock-screen / banner presentation
            TrialLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 12.0 / 255.0, green: 12.0 / 255.0, blue: 16.0 / 255.0))
                .activitySystemActionForegroundColor(Color(red: 246.0 / 255.0, green: 245.0 / 255.0, blue: 242.0 / 255.0))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    WidgetBrandTile(
                        letter: context.attributes.fallbackLetter,
                        name: context.attributes.name,
                        colorHex: context.attributes.brandColorHex,
                        size: 36
                    )
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.trialEndDate,
                         countsDown: true)
                        .font(.system(size: 18, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(amber)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ink)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(amber)
                        Text("试用到期后将自动扣 \(context.attributes.priceText)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ink.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            } compactLeading: {
                WidgetBrandTile(
                    letter: context.attributes.fallbackLetter,
                    name: context.attributes.name,
                    colorHex: context.attributes.brandColorHex,
                    size: 20
                )
            } compactTrailing: {
                Text(context.state.trialEndDate, style: .timer)
                    .monospacedDigit()
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(amber)
                    .frame(maxWidth: 56)
            } minimal: {
                WidgetBrandTile(
                    letter: context.attributes.fallbackLetter,
                    name: context.attributes.name,
                    colorHex: context.attributes.brandColorHex,
                    size: 18
                )
            }
            .widgetURL(URL(string: "subscribe://trial/\(context.attributes.subID)"))
            .keylineTint(Color(widgetHex: context.attributes.brandColorHex))
        }
    }

    private var amber: Color { Color(red: 212.0 / 255.0, green: 168.0 / 255.0, blue: 72.0 / 255.0) }
    private var ink: Color { Color(red: 246.0 / 255.0, green: 245.0 / 255.0, blue: 242.0 / 255.0) }
}

// MARK: - Lock-screen / banner

private struct TrialLockScreenView: View {
    let context: ActivityViewContext<TrialActivityAttributes>

    private var amber: Color { Color(red: 212.0 / 255.0, green: 168.0 / 255.0, blue: 72.0 / 255.0) }
    private var ink: Color { Color(red: 246.0 / 255.0, green: 245.0 / 255.0, blue: 242.0 / 255.0) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            WidgetBrandTile(
                letter: context.attributes.fallbackLetter,
                name: context.attributes.name,
                colorHex: context.attributes.brandColorHex,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(amber)
                    Text("试用结束时需退订")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ink.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(timerInterval: Date()...context.state.trialEndDate,
                     countsDown: true)
                    .font(.system(size: 22, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(amber)
                    .multilineTextAlignment(.trailing)
                Text("到期后扣 \(context.attributes.priceText)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ink.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
