import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case applications = "Applications"
    case cvLibrary = "CV Library"
    case callMatch = "Call Match"
    case settings = "Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .dashboard:
            return "chart.pie.fill"
        case .applications:
            return "folder.fill"
        case .cvLibrary:
            return "doc.richtext.fill"
        case .callMatch:
            return "phone.badge.waveform.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.symbolName) }
            .tag(AppTab.dashboard)

            NavigationStack {
                ApplicationsView()
            }
            .tabItem { Label(AppTab.applications.rawValue, systemImage: AppTab.applications.symbolName) }
            .tag(AppTab.applications)

            NavigationStack {
                CVLibraryView()
            }
            .tabItem { Label(AppTab.cvLibrary.rawValue, systemImage: AppTab.cvLibrary.symbolName) }
            .tag(AppTab.cvLibrary)

            NavigationStack {
                CallMatchView()
            }
            .tabItem { Label(AppTab.callMatch.rawValue, systemImage: AppTab.callMatch.symbolName) }
            .tag(AppTab.callMatch)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.rawValue, systemImage: AppTab.settings.symbolName) }
            .tag(AppTab.settings)
        }
        .task {
            await DemoDataSeeder.seedIfNeeded(modelContext: modelContext)
        }
    }
}
