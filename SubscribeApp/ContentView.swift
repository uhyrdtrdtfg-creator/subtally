import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var tab: AppTab = {
        if let raw = ProcessInfo.processInfo.environment["LAUNCH_TAB"],
           let t = AppTab(rawValue: raw) {
            return t
        }
        return .home
    }()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasOnboarded")
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.modelContext) private var context

    private var palette: Palette {
        let scheme: ColorScheme = settings.theme.colorScheme ?? systemScheme
        return scheme == .dark ? .dark : .light
    }

    var body: some View {
        ZStack {
            palette.bg.ignoresSafeArea()
            Group {
                switch tab {
                case .home:     HomeView()
                case .trends:   TrendsView()
                case .schedule: ScheduleView()
                case .me:       MeView()
                }
            }
            .transition(.opacity.combined(with: .offset(y: 4)))
            .animation(.easeOut(duration: 0.24), value: tab)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: $tab)
        }
        .environment(\.palette, palette)
        .preferredColorScheme(settings.theme.colorScheme)
        .tint(palette.ink)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { }
                .interactiveDismissDisabled()
                .environment(\.palette, palette)
        }
    }
}
