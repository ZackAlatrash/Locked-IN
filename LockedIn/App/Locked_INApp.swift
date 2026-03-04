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

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue
    @StateObject private var commitmentSystemStore: CommitmentSystemStore
    @StateObject private var planStore: PlanStore
    @StateObject private var onboardingCoordinator = OnboardingCoordinator(
        flow: OnboardingFlow(),
        engine: OnboardingEngine()
    )

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
        .environmentObject(commitmentSystemStore)
        .environmentObject(planStore)
        .onAppear {
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
            commitmentSystemStore.runDailyIntegrityTick(referenceDate: Date())
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                commitmentSystemStore.runDailyIntegrityTick(referenceDate: Date())
            }
        }
    }

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark
    }
}
