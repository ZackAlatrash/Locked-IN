import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    var cockpitStyle: CockpitModernStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    var primaryAccentColor: Color {
        switch self {
        case .light: return Color(hex: "#7BA70A")
        case .dark: return Color(hex: "#A3FF12")
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject private var store: CommitmentSystemStore
    @State private var selectedTab: MainTab = .cockpit
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue

    private var appAppearanceMode: AppAppearanceMode {
        get { AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark }
        set { appAppearanceModeRaw = newValue.rawValue }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CockpitView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Cockpit", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(MainTab.cockpit)

            NavigationStack {
                PlanScreen(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Plan", systemImage: "map.fill")
            }
            .tag(MainTab.plan)

            NavigationStack {
                CockpitLogsScreen(selectedTab: $selectedTab)
                    .environmentObject(store)
            }
            .tabItem {
                Label("Logs", systemImage: "list.bullet.rectangle")
            }
            .tag(MainTab.logs)
        }
        .tint(appAppearanceMode.primaryAccentColor)
        .preferredColorScheme(appAppearanceMode.colorScheme)
    }
}
