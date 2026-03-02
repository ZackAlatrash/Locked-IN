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
                PlanPlaceholderView(selectedTab: $selectedTab)
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

private struct PlanPlaceholderView: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject private var store: CommitmentSystemStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showProfile = false

    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    private var cardBackground: Color { isDarkMode ? Color(hex: "#1C1C1E") : Color.white }
    private var titleColor: Color { isDarkMode ? Theme.Colors.textPrimary : Color(hex: "101827") }
    private var subtitleColor: Color { isDarkMode ? Theme.Colors.textMuted : Color(hex: "6B7280") }
    private var navItemColor: Color { isDarkMode ? Theme.Colors.textSecondary : Color(hex: "111827") }
    private var accentColor: Color { isDarkMode ? Color(hex: "#A3FF12") : Color(hex: "#7BA70A") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                statCard(title: "Active Protocols", value: "\(store.activeNonNegotiables.count)")
                statCard(title: "Allowed Capacity", value: "\(store.allowedCapacity)")
                statCard(title: "Current Streak", value: "\(store.currentStreakDays) days")
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    selectedTab = .logs
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))

                        Circle()
                            .fill(accentColor)
                            .frame(width: 7, height: 7)
                            .offset(x: 5, y: -3)
                    }
                    .foregroundColor(navItemColor)
                }
                .accessibilityLabel("Open logs")

                Button {
                    showProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(navItemColor)
                }
                .accessibilityLabel("Open profile")
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfilePlaceholderView()
            }
        }
    }

    func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(subtitleColor)
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(titleColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}
