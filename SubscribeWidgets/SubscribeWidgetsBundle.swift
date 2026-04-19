import WidgetKit
import SwiftUI

@main
struct SubscribeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpcomingWidget()
        MonthlyTotalWidget()
        TrialLiveActivity()
    }
}
