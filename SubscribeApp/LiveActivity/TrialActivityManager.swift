import Foundation
import ActivityKit
import SwiftData

/// Coordinates start / update / end of `TrialActivityAttributes` Live Activities
/// for free-trial subscriptions whose end date is within the next 48 hours.
///
/// Single-source-of-truth: `syncAll(context:)` should be invoked
///   1. on app launch
///   2. after any subscription edit (best-effort)
/// to bring system activities into agreement with current SwiftData state.
@MainActor
final class TrialActivityManager {
    static let shared = TrialActivityManager()

    /// Window inside which we surface the countdown — anything further out
    /// would be noisy and waste the system's activity budget.
    private let leadWindow: TimeInterval = 48 * 60 * 60

    /// In-memory tracker keyed by `Subscription.stableID`. Survives across
    /// `syncAll` calls within a single app process; rebuilt from `Activity.activities`
    /// on first access to handle cold-start (e.g. after the app was killed but the
    /// activity is still on the lock-screen).
    private var tracked: [String: Activity<TrialActivityAttributes>] = [:]
    private var hasHydrated = false

    private init() {}

    // MARK: - Public API

    /// Walk all subscriptions; ensure activities mirror reality.
    ///   - trial && endDate in (now, now + 48h]   → start or update
    ///   - trial && endDate <= now                → end (trial expired)
    ///   - !isFreeTrial                            → end (user converted/cancelled)
    func syncAll(context: ModelContext) async {
        hydrateIfNeeded()
        let descriptor = FetchDescriptor<Subscription>()
        guard let all = try? context.fetch(descriptor) else { return }

        let now = Date()
        var seenSubIDs = Set<String>()

        for sub in all {
            seenSubIDs.insert(sub.stableID)
            guard sub.isFreeTrial, let endDate = sub.trialEndDate else {
                await end(subID: sub.stableID)
                continue
            }
            if endDate <= now {
                await end(subID: sub.stableID)
                continue
            }
            if endDate.timeIntervalSince(now) <= leadWindow {
                await startOrUpdate(for: sub)
            } else {
                // Trial exists but is too far out — make sure no stale activity is showing.
                await end(subID: sub.stableID)
            }
        }

        // Cleanup orphans: activities whose backing Subscription was deleted.
        for orphanID in tracked.keys where !seenSubIDs.contains(orphanID) {
            await end(subID: orphanID)
        }
    }

    /// Start a new activity for `sub` if none exists, otherwise push an updated
    /// content state. No-ops when the user has globally disabled Live Activities.
    func startOrUpdate(for sub: Subscription) async {
        hydrateIfNeeded()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let endDate = sub.trialEndDate else { return }

        let attributes = TrialActivityAttributes(
            subID: sub.stableID,
            name: sub.name,
            brandColorHex: sub.brandColorHex,
            fallbackLetter: sub.fallbackLetter,
            priceText: priceText(for: sub)
        )
        let state = TrialActivityAttributes.ContentState(trialEndDate: endDate)
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60 * 60))

        if let existing = tracked[sub.stableID] {
            await existing.update(content)
            return
        }

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            tracked[sub.stableID] = activity
        } catch {
            // Likely: budget exhausted, or user disabled activities mid-flight.
            // Safe to swallow — next syncAll() will retry.
        }
    }

    /// End the activity for a given subID, immediately removing it from the lock-screen.
    func end(subID: String) async {
        hydrateIfNeeded()
        guard let activity = tracked[subID] else { return }
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: nil
        )
        await activity.end(finalContent, dismissalPolicy: .immediate)
        tracked.removeValue(forKey: subID)
    }

    // MARK: - Private

    /// Reattach in-process tracker to system-side activities that survived an
    /// app relaunch. Without this we'd leak activities (no way to update or end
    /// them from the new process).
    private func hydrateIfNeeded() {
        guard !hasHydrated else { return }
        hasHydrated = true
        for activity in Activity<TrialActivityAttributes>.activities {
            tracked[activity.attributes.subID] = activity
        }
    }

    private func priceText(for sub: Subscription) -> String {
        let symbol = sub.currency.symbol
        let v = sub.price
        if abs(v - v.rounded()) < 0.01 {
            return "\(symbol)\(Int(v.rounded()))"
        }
        return "\(symbol)\(String(format: "%.2f", v))"
    }
}
