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
    @State private var wasRecoveryActive = false

    private var appAppearanceMode: AppAppearanceMode {
        get { AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark }
        set { appAppearanceModeRaw = newValue.rawValue }
    }

    private var isRecoveryThemeActive: Bool {
        store.isSystemStable == false
    }

    private var appAccentColor: Color {
        if isRecoveryThemeActive {
            return appAppearanceMode == .dark ? Color(hex: "#EF4444") : Color(hex: "#B91C1C")
        }
        return appAppearanceMode.primaryAccentColor
    }

    var body: some View {
        let isRecoveryPopupPresented = router.presentRecoveryEntry
        let isDailyCheckInPresented = router.presentDailyCheckIn && isRecoveryPopupPresented == false
        let isBlockingPopupPresented = isRecoveryPopupPresented || isDailyCheckInPresented

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
            .blur(radius: isBlockingPopupPresented ? 9 : 0)
            .scaleEffect(isBlockingPopupPresented ? 0.985 : 1)
            .allowsHitTesting(isBlockingPopupPresented == false)
            .accessibilityHidden(isBlockingPopupPresented)

            if isRecoveryPopupPresented {
                recoveryPopupOverlay
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity.combined(with: .scale(scale: 0.97))
                        )
                    )
                    .zIndex(2)
            } else if isDailyCheckInPresented {
                dailyCheckInPopupOverlay
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
        .tint(appAccentColor)
        .preferredColorScheme(appAppearanceMode.colorScheme)
        .animation(reduceMotion ? .none : Theme.Animation.context, value: appAppearanceModeRaw)
        .animation(
            reduceMotion ? .none : .spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.08),
            value: isBlockingPopupPresented
        )
        .onAppear {
            wasRecoveryActive = store.system.nonNegotiables.contains(where: { $0.state == .recovery })
            evaluateRecoveryEntryPresentation(now: appClock.now)
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                evaluateRecoveryEntryPresentation(now: appClock.now)
                evaluateDailyCheckInAutoPresentation(now: appClock.now)
            }
        }
        .onChange(of: router.selectedTab) { _ in
            Haptics.selection()
            evaluateRecoveryEntryPresentation(now: appClock.now)
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onChange(of: appClock.simulatedNow) { _ in
            evaluateRecoveryEntryPresentation(now: appClock.now)
            evaluateDailyCheckInAutoPresentation(now: appClock.now)
        }
        .onChange(of: devRuntime.forceShowDailyCheckInToken) { token in
            guard token != nil else { return }
            if router.presentRecoveryEntry == false {
                router.requestDailyCheckInPresentation()
            }
            devRuntime.consumeDailyCheckInPresentationRequest()
        }
        .onChange(of: store.system) { system in
            let isRecoveryActive = system.nonNegotiables.contains(where: { $0.state == .recovery })
            if wasRecoveryActive && isRecoveryActive == false {
                planStore.finalizeRecoveryAllocationStatuses(referenceDate: appClock.now)
            }
            wasRecoveryActive = isRecoveryActive
            evaluateRecoveryEntryPresentation(now: appClock.now)
            if isRecoveryActive {
                router.dismissDailyCheckIn()
            }
        }
    }
}

private extension MainAppView {
    var dailyCheckInPopupOverlay: some View {
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

    var recoveryPopupOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.24))
                .ignoresSafeArea()

            RecoveryModePopup(
                commitmentStore: store,
                planStore: planStore,
                referenceDateProvider: { appClock.now }
            ) {
                router.dismissRecoveryEntry()
                evaluateDailyCheckInAutoPresentation(now: appClock.now)
            }
            .frame(maxWidth: 640)
            .frame(maxHeight: 760)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        appAppearanceMode == .dark
                            ? Color(hex: "#F87171").opacity(0.36)
                            : Color(hex: "#B91C1C").opacity(0.26),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.34), radius: 28, x: 0, y: 12)
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
    }

    func evaluateRecoveryEntryPresentation(now: Date = Date()) {
        if store.recoveryEntryContext(referenceDate: now) != nil {
            router.requestRecoveryEntryPresentation()
            router.dismissDailyCheckIn()
        } else {
            if store.system.nonNegotiables.contains(where: { $0.state == .recovery }) == false {
                planStore.finalizeRecoveryAllocationStatuses(referenceDate: now)
            }
            router.dismissRecoveryEntry()
        }
    }

    func evaluateDailyCheckInAutoPresentation(now: Date = Date()) {
        if router.presentRecoveryEntry || store.recoveryEntryContext(referenceDate: now) != nil {
            return
        }

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
