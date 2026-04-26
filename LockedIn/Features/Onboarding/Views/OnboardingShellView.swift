//
//  OnboardingShellView.swift
//  LockedIn
//
//  Persistent onboarding shell with a floating frameless header and gradient-scrim footer.
//  Content views extend FULL SCREEN. Navigation direction is tracked so transitions
//  slide the correct way for both forward and back movement.
//

import SwiftUI

struct OnboardingShellView: View {
    @ObservedObject private var coordinator: OnboardingCoordinator
    @StateObject private var shellVM: OnboardingShellViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showPaywall  = false
    @State private var goingForward = true    // drives transition direction

    // Matches the Cockpit stable-state background
    private var shellBackground: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(hex: "#F8F9FB")
            }
        }
        .ignoresSafeArea()
    }

    private var footerBaseColor: Color {
        colorScheme == .dark ? Color(hex: "#020617") : Color(hex: "#F8F9FB")
    }

    private let progressActiveColor = Color(hex: "#22D3EE")

    // Direction-aware transition — clean slide + opacity, no scale (keeps it snappy)
    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: goingForward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    init(coordinator: OnboardingCoordinator, onComplete: (() -> Void)? = nil) {
        self._coordinator = ObservedObject(wrappedValue: coordinator)
        _shellVM = StateObject(wrappedValue: OnboardingShellViewModel(coordinator: coordinator, onComplete: onComplete))
    }

    var body: some View {
        shellBackground
            .overlay {
                contentForCurrentStep
                    .ignoresSafeArea()
            }
            .overlay(alignment: .top)    { headerSection }
            .overlay(alignment: .bottom) { footerSection }
            .ignoresSafeArea()
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallContentView(
                    onStartTrial: {
                        Haptics.success()
                        showPaywall = false
                        shellVM.completeOnboarding()
                    },
                    onDismiss: {
                        Haptics.selection()
                        shellVM.completeOnboarding()
                    }
                )
                .ignoresSafeArea()
            }
    }
}

// MARK: - Helpers
private extension OnboardingShellView {
    var presentationConfig: OnboardingPresentationConfig {
        OnboardingPresentationConfig.config(for: shellVM.currentStep)
    }

    var currentStepIndex: Int {
        let total = OnboardingPresentationConfig.totalSteps
        guard total > 0 else { return 1 }
        let index = Int(round(shellVM.progress * Double(total)))
        return min(max(index, 1), total)
    }

    func advance() {
        guard !coordinator.isTransitioning, coordinator.canAdvanceCurrentStep else {
            Haptics.warning()
            return
        }

        goingForward = true
        Haptics.selection()

        let result = shellVM.next()
        if case .reachedEnd = result {
            showPaywall = true
        }
    }
}

// MARK: - Header
private extension OnboardingShellView {
    var headerSection: some View {
        VStack(spacing: 0) {
            ProgressIndicator(
                totalSteps: OnboardingPresentationConfig.totalSteps,
                currentStep: currentStepIndex,
                activeColor: progressActiveColor
            )
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, 56)

            Text(String(format: "%02d / %02d", currentStepIndex, OnboardingPresentationConfig.totalSteps))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2.0)
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Theme.Spacing.xs)

            HStack {
                // Back — sets direction to backward before stepping
                Button {
                    goingForward = false
                    Haptics.selection()
                    _ = shellVM.back()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .opacity(presentationConfig.showBackButton ? 1 : 0)
                .disabled(!presentationConfig.showBackButton)

                Spacer()

                // Skip — always moves forward in the flow
                Button {
                    goingForward = true
                    Haptics.selection()
                    _ = shellVM.skip()
                } label: {
                    Text("SKIP")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .opacity(presentationConfig.showSkipButton ? 1 : 0)
                .disabled(!presentationConfig.showSkipButton)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.xxs)
        }
    }
}

// MARK: - Content
private extension OnboardingShellView {
    @ViewBuilder
    var contentForCurrentStep: some View {
        ZStack {
            switch shellVM.currentStep {
            case .welcome:
                WelcomeContentView()
                    .transition(screenTransition)
                    .id(OnboardingStep.welcome.id)

            case .identityWarning:
                IdentityWarningContentView()
                    .transition(screenTransition)
                    .id(OnboardingStep.identityWarning.id)

            case .failureLoop:
                FailureLoopContentView()
                    .transition(screenTransition)
                    .id(OnboardingStep.failureLoop.id)

            case .coreDifferentiation:
                CoreDifferentiationContentView()
                    .transition(screenTransition)
                    .id(OnboardingStep.coreDifferentiation.id)

            case .commitmentAgreement:
                CommitmentAgreementContentView(viewModel: coordinator.commitmentAgreementVM)
                    .transition(screenTransition)
                    .id(OnboardingStep.commitmentAgreement.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        // Snappy spring — settles in ~0.28s with no bounce
        .animation(.spring(response: 0.3, dampingFraction: 0.92), value: shellVM.currentStep)
    }
}

// MARK: - Footer
private extension OnboardingShellView {
    private var ctaSubtitleReservedHeight: CGFloat { 32 }

    var footerSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear,                          location: 0),
                    .init(color: footerBaseColor.opacity(0.72),   location: 0.4),
                    .init(color: footerBaseColor.opacity(0.97),   location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)

            VStack(spacing: Theme.Spacing.md) {
                // .id() forces a new view when the title changes, triggering the transition
                PrimaryButton(
                    title: presentationConfig.ctaTitle,
                    showArrow: true,
                    backgroundColor: progressActiveColor,
                    foregroundColor: Color(hex: "#020617"),
                    action: { advance() }
                )
                .disabled(coordinator.isTransitioning || !coordinator.canAdvanceCurrentStep)
                .opacity((coordinator.isTransitioning || !coordinator.canAdvanceCurrentStep) ? 0.5 : 1.0)

                Text(presentationConfig.ctaSubtitle.uppercased())
                    .id(presentationConfig.ctaSubtitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: presentationConfig.ctaSubtitle)
                    .font(Theme.Typography.captionSmall())
                    .tracking(Theme.Typography.letterSpacingWidest * 11)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .frame(height: ctaSubtitleReservedHeight, alignment: .top)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingShellView_Previews: PreviewProvider {
    static var previews: some View {
        LockedInAppRoot()
            .preferredColorScheme(.dark)
    }
}
