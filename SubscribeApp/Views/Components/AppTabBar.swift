import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, trends, schedule, me
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .trends: return "Trends"
        case .schedule: return "Schedule"
        case .me: return "Me"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .trends: return "chart.bar"
        case .schedule: return "calendar"
        case .me: return "person"
        }
    }
}

struct AppTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20, weight: .regular))
                        Text(tab.title).font(AppFont.geist(10, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? palette.ink : palette.ink3)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
        .background(palette.tabbarBg)
        .background(palette.tabbarBg.ignoresSafeArea(.container, edges: .bottom))
    }
}
