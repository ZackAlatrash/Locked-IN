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
    @State private var didInitializeMotionSession = false

    init() {
        let repository = JSONFileCommitmentSystemRepository()
        let nonNegotiableEngine = NonNegotiableEngine()
        let systemEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

        _commitmentSystemStore = StateObject(
            wrappedValue: CommitmentSystemStore(
                repository: repository,
                systemEngine: systemEngine,
                nonNegotiableEngine: nonNegotiableEngine
            )
        )
        _planStore = StateObject(
            wrappedValue: PlanStore(repository: JSONFilePlanAllocationRepository())
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
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                commitmentSystemStore.runDailyIntegrityTick(referenceDate: appClock.now)
            }
        }
    }

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark
    }
}
