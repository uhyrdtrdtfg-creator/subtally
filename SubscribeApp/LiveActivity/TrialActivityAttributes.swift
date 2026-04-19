import Foundation
import ActivityKit

/// Static attributes + dynamic content state for a free-trial countdown Live Activity.
/// Used by both the main app (to start/update/end activities) and the widget extension
/// (to render the lock-screen UI + Dynamic Island).
struct TrialActivityAttributes: ActivityAttributes {
    // MARK: - Static (immutable per activity instance)
    /// Stable Subscription.stableID — used to key activities to subscriptions.
    let subID: String
    /// Display name of the subscription (e.g. "Netflix").
    let name: String
    /// Brand color as a hex string without leading `#`, e.g. "D4A848".
    let brandColorHex: String
    /// 1–2 character fallback letter for the brand tile.
    let fallbackLetter: String
    /// Fully formatted post-trial charge text, e.g. "¥68" or "$9.99".
    let priceText: String

    // MARK: - Dynamic (can be updated while activity is running)
    struct ContentState: Codable, Hashable {
        /// The moment the free trial ends — drives all countdown views via
        /// `Text(timerInterval:)` / `Text(_:style:.timer)`.
        var trialEndDate: Date
    }
}
