//
//  Locked_INApp.swift
//  Locked IN
//
//  Single app entry + root flow wiring
//

import SwiftUI

@main
struct Locked_INApp: App {
    var body: some Scene {
        WindowGroup {
            LockedInAppRoot()
        }
    }
}

/// Root view factory for the LockedIn app
struct LockedInAppRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(WalkthroughController.StorageKeys.hasCompletedWalkthrough) private var hasCompletedWalkthrough = false
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue
    @AppStorage("phase1MotionSessionID") private var phase1MotionSessionID = ""
    @StateObject private var appClock = AppClock()
    @StateObject private var devRuntime = DevRuntimeState()
    @StateObject private var commitmentSystemStore: CommitmentSystemStore
    @StateObject private var planStore: PlanStore
    @StateObject private var onboardingCoordinator = OnboardingCoordinator(
        flow: OnboardingFlow(),
        engine: OnboardingEngine()
    )
    @StateObject private var walkthroughController = WalkthroughController()
    @State private var didInitializeMotionSession = false

    init() {
        let repository = JSONFileCommitmentSystemRepository()
        let nonNegotiableEngine = NonNegotiableEngine()
        let systemEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
        let policyEngine = CommitmentPolicyEngine()

        _commitmentSystemStore = StateObject(
            wrappedValue: CommitmentSystemStore(
                repository: repository,
                systemEngine: systemEngine,
                nonNegotiableEngine: nonNegotiableEngine,
                policy: policyEngine
            )
        )
        _planStore = StateObject(
            wrappedValue: PlanStore(
                repository: JSONFilePlanAllocationRepository(),
                policy: policyEngine
            )
        )
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainAppView()
            } else {
                OnboardingShellView(
                    coordinator: onboardingCoordinator,
                    onComplete: {
                        hasCompletedOnboarding = true
                        maybeStartWalkthrough()
                    }
                )
            }
        }
        .preferredColorScheme(appAppearanceMode.colorScheme)
        .animation(reduceMotion ? .none : Theme.Animation.context, value: appAppearanceModeRaw)
        .environmentObject(commitmentSystemStore)
        .environmentObject(planStore)
        .environmentObject(appClock)
        .environmentObject(devRuntime)
        .environmentObject(walkthroughController)
        .onAppear {
            if didInitializeMotionSession == false {
                didInitializeMotionSession = true
                phase1MotionSessionID = UUID().uuidString
            }
            let freshStartResetKey = "didRunFreshStartReset20260303"
            if UserDefaults.standard.bool(forKey: freshStartResetKey) == false {
                hasCompletedOnboarding = false
                commitmentSystemStore.clearAllNonNegotiables()
                planStore.clearAllAllocations()
                UserDefaults.standard.set(true, forKey: freshStartResetKey)
            }
            let protocolResetKey = "didRunProtocolReset20260303"
            if UserDefaults.standard.bool(forKey: protocolResetKey) == false {
                commitmentSystemStore.clearAllNonNegotiables()
                planStore.clearAllAllocations()
                UserDefaults.standard.set(true, forKey: protocolResetKey)
            }
            commitmentSystemStore.runDailyIntegrityTick(referenceDate: appClock.now)
            // Crash recovery: restore stash if a walkthrough restart was interrupted
            if commitmentSystemStore.hasWalkthroughStash && !walkthroughController.isActive {
                commitmentSystemStore.restoreFromWalkthroughStash()
                planStore.restoreFromWalkthroughStash()
            }
            maybeStartWalkthrough()
        }
        .onChange(of: walkthroughController.isActive) { _, isNowActive in
            guard !isNowActive, walkthroughController.isRestartMode else { return }
            commitmentSystemStore.restoreFromWalkthroughStash()
            planStore.restoreFromWalkthroughStash()
            walkthroughController.clearRestartMode()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                commitmentSystemStore.runDailyIntegrityTick(referenceDate: appClock.now)
                maybeStartWalkthrough()
            }
        }
        .onChange(of: appClock.simulatedNow) { _, _ in
            commitmentSystemStore.runDailyIntegrityTick(referenceDate: appClock.now)
        }
        .onChange(of: hasCompletedOnboarding) { _, _ in
            maybeStartWalkthrough()
        }
    }

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark
    }

    private func maybeStartWalkthrough() {
        guard hasCompletedOnboarding else { return }
        guard hasCompletedWalkthrough == false else { return }
        guard walkthroughController.isActive == false else { return }
        walkthroughController.start()
    }
}
