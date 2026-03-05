import SwiftUI
import Combine

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
        case .light: return Color(hex: "#0369A1")
        case .dark: return Color(hex: "#22D3EE")
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject private var store: CommitmentSystemStore
    @EnvironmentObject private var planStore: PlanStore
    @EnvironmentObject private var appClock: AppClock
    @EnvironmentObject private var devRuntime: DevRuntimeState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var router = AppRouter()
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue
    @AppStorage(DailyCheckInPolicy.Keys.lastCompletedDay) private var dailyCheckInLastCompletedDay = ""
    @AppStorage(DailyCheckInPolicy.Keys.lastPromptedDay) private var dailyCheckInLastPromptedDay = ""
    @AppStorage(DailyCheckInPolicy.Keys.repromptedDay) private var dailyCheckInRepromptedDay = ""
    @AppStorage(DailyCheckInPolicy.Keys.deferredUntilTimestamp) private var dailyCheckInDeferredUntilTimestamp: Double = 0
    @AppStorage(DailyCheckInPolicy.Keys.hour) private var dailyCheckInHour = 18
    @AppStorage(DailyCheckInPolicy.Keys.minute) private var dailyCheckInMinute = 0

    private var appAppearanceMode: AppAppearanceMode {
        get { AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark }
        set { appAppearanceModeRaw = newValue.rawValue }
    }

    var body: some View {
        ZStack {
            TabView(selection: $router.selectedTab) {
                NavigationStack {
                    CockpitView(
                        selectedTab: $router.selectedTab,
                        onRequestDailyCheckIn: {
                            router.requestDailyCheckInPresentation()
                        }
                    )
                }
                .tabItem {
                    Label("Cockpit", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(MainTab.cockpit)

                NavigationStack {
                    PlanScreen(selectedTab: $router.selectedTab)
                }
                .tabItem {
                    Label("Plan", systemImage: "map.fill")
                }
                .tag(MainTab.plan)

                NavigationStack {
                    CockpitLogsScreen(selectedTab: $router.selectedTab)
                        .environmentObject(store)
                }
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.logs)
            }
            .blur(radius: router.presentDailyCheckIn ? 9 : 0)
            .scaleEffect(router.presentDailyCheckIn ? 0.985 : 1)
            .allowsHitTesting(router.presentDailyCheckIn == false)
            .accessibilityHidden(router.presentDailyCheckIn)

            if router.presentDailyCheckIn {
                popupOverlay
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity.combined(with: .scale(scale: 0.97))
                        )
                    )
                    .zIndex(2)
            }
        }
        .environmentObject(router)
        .tint(appAppearanceMode.primaryAccentColor)
        .preferredColorScheme(appAppearanceMode.colorScheme)
        .animation(reduceMotion ? .none : Theme.Animation.context, value: appAppearanceModeRaw)
        .animation(
            reduceMotion ? .none : .spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.08),
            value: router.presentDailyCheckIn
        )
        .onAppear {
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                evaluateDailyCheckInAutoPresentation(now: appClock.now)
            }
        }
        .onChange(of: router.selectedTab) { _ in
            Haptics.selection()
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onReceive(appClock.objectWillChange) { _ in
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onChange(of: devRuntime.forceShowDailyCheckInToken) { token in
            guard token != nil else { return }
            router.requestDailyCheckInPresentation()
            devRuntime.consumeDailyCheckInPresentationRequest()
        }
    }
}

private extension MainAppView {
    var popupOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .ignoresSafeArea()

            DailyCheckInFlowView(
                commitmentStore: store,
                planStore: planStore,
                router: router,
                referenceDateProvider: { appClock.now },
                isPopup: true
            ) { outcome in
                handleDailyCheckInFinished(outcome)
            }
            .frame(maxWidth: 680)
            .frame(maxHeight: 780)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        appAppearanceMode == .dark
                            ? Color.white.opacity(0.16)
                            : Color.black.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 28, x: 0, y: 12)
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
    }

    func evaluateDailyCheckInAutoPresentation(now: Date = Date()) {
        if router.presentDailyCheckIn {
            return
        }

        let todayIdentifier = DailyCheckInPolicy.dayIdentifier(for: now)
        if dailyCheckInLastPromptedDay != todayIdentifier {
            dailyCheckInRepromptedDay = ""
            if dailyCheckInLastCompletedDay != todayIdentifier {
                dailyCheckInDeferredUntilTimestamp = 0
            }
        }

        guard let promptType = DailyCheckInPolicy.promptType(
            now: now,
            lastCompletedDay: dailyCheckInLastCompletedDay,
            lastPromptedDay: dailyCheckInLastPromptedDay,
            repromptedDay: dailyCheckInRepromptedDay,
            deferredUntilTimestamp: dailyCheckInDeferredUntilTimestamp,
            hour: dailyCheckInHour,
            minute: dailyCheckInMinute
        ) else {
            return
        }

        switch promptType {
        case .initial:
            dailyCheckInLastPromptedDay = todayIdentifier
            dailyCheckInDeferredUntilTimestamp = 0
        case .reprompt:
            dailyCheckInRepromptedDay = todayIdentifier
        }

        Haptics.softImpact()
        router.requestDailyCheckInPresentation()
    }

    func handleDailyCheckInFinished(_ outcome: DailyCheckInDismissOutcome) {
        let now = appClock.now
        let todayIdentifier = DailyCheckInPolicy.dayIdentifier(for: now)

        if outcome.completed || outcome.unresolvedCount == 0 {
            dailyCheckInLastCompletedDay = todayIdentifier
            dailyCheckInLastPromptedDay = todayIdentifier
            dailyCheckInRepromptedDay = todayIdentifier
            dailyCheckInDeferredUntilTimestamp = 0
        } else {
            let threshold = DailyCheckInPolicy.thresholdDate(
                on: now,
                hour: dailyCheckInHour,
                minute: dailyCheckInMinute
            )
            if now >= threshold && dailyCheckInLastPromptedDay != todayIdentifier {
                dailyCheckInLastPromptedDay = todayIdentifier
            }
            dailyCheckInDeferredUntilTimestamp = DailyCheckInPolicy.deferredTimestamp(from: now, minutes: 30)
        }

        Haptics.selection()
        router.dismissDailyCheckIn()
    }
}
