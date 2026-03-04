//
//  OnboardingShellView.swift
//  LockedIn
//
//  Persistent onboarding shell with fixed header (progress bar + icons)
//  and fixed footer (CTA button + subtitle).
//  Content views extend FULL SCREEN (behind header/footer).
//

import SwiftUI

struct OnboardingShellView: View {
    @ObservedObject private var coordinator: OnboardingCoordinator
    @StateObject private var shellVM: OnboardingShellViewModel

    @State private var showPaywall = false

    init(coordinator: OnboardingCoordinator, onComplete: (() -> Void)? = nil) {
        self._coordinator = ObservedObject(wrappedValue: coordinator)
        _shellVM = StateObject(wrappedValue: OnboardingShellViewModel(coordinator: coordinator, onComplete: onComplete))
    }

    var body: some View {
        ZStack {
            contentForCurrentStep
                .ignoresSafeArea()

            VStack {
                headerSection
                Spacer()
            }

            VStack {
                Spacer()
                footerSection
            }
        }
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
        let result = shellVM.next()
        switch result {
        case .advanced:
            Haptics.selection()
            break
        case .reachedEnd:
            Haptics.selection()
            showPaywall = true
        case .blocked:
            Haptics.warning()
            break
        }
    }
}

private extension OnboardingShellView {
    var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    if presentationConfig.showBackButton {
                        Haptics.selection()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            _ = shellVM.back()
                        }
                    }
                }) {
                    Image(systemName: presentationConfig.showBackButton ? "arrow.left" : "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.textSubtle)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Spacer()

                Button(action: {
                    if presentationConfig.showSkipButton {
                        Haptics.selection()
                        _ = shellVM.skip()
                    }
                }) {
                    Group {
                        if presentationConfig.showSkipButton {
                            Text("Skip")
                                .font(Theme.Typography.bodyMedium())
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                    .foregroundColor(Theme.Colors.textSubtle)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, 60)
            .padding(.bottom, Theme.Spacing.xl)

            ProgressIndicator(
                totalSteps: OnboardingPresentationConfig.totalSteps,
                currentStep: currentStepIndex
            )
            .padding(.horizontal, Theme.Spacing.xl)

            Text(presentationConfig.stepLabel.uppercased())
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 10)
                .foregroundColor(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.md)
        }
    }
}

private extension OnboardingShellView {
    @ViewBuilder
    var contentForCurrentStep: some View {
        ZStack {
            switch shellVM.currentStep {
            case .identityWarning:
                IdentityWarningContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.identityWarning.id)

            case .failureLoop:
                FailureLoopContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.failureLoop.id)

            case .userHistory:
                UserHistoryContentView(viewModel: coordinator.userHistoryVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.userHistory.id)

            case .coreDifferentiation:
                CoreDifferentiationContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.coreDifferentiation.id)

            case .nonNegotiables:
                NonNegotiablesContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.nonNegotiables.id)

            case .aiRegulator:
                AIRegulatorContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.aiRegulator.id)

            case .commitmentAgreement:
                CommitmentAgreementContentView(viewModel: coordinator.commitmentAgreementVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(OnboardingStep.commitmentAgreement.id)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: shellVM.currentStep)
    }
}

private extension OnboardingShellView {
    private var ctaSubtitleReservedHeight: CGFloat { 32 }

    var footerSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Theme.Colors.backgroundPrimary.opacity(0.8),
                    Theme.Colors.backgroundPrimary
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(
                    title: presentationConfig.ctaTitle,
                    showArrow: true,
                    action: {
                        advance()
                    }
                )
                .disabled(coordinator.isTransitioning || !coordinator.canAdvanceCurrentStep)
                .opacity((coordinator.isTransitioning || !coordinator.canAdvanceCurrentStep) ? 0.5 : 1.0)

                Text(presentationConfig.ctaSubtitle.uppercased())
                    .font(Theme.Typography.captionSmall())
                    .tracking(Theme.Typography.letterSpacingWidest * 11)
                    .foregroundColor(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .frame(height: ctaSubtitleReservedHeight, alignment: .top)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, 40)
            .background(Theme.Colors.backgroundPrimary)
        }
    }
}

struct OnboardingShellView_Previews: PreviewProvider {
    static var previews: some View {
        LockedInAppRoot()
        .preferredColorScheme(.dark)
    }
}
