//
//  OnboardingShellView.swift
//  LockedIn
//
//  Persistent onboarding shell with fixed header (progress bar + icons)
//  and fixed footer (CTA button + subtitle).
//  Content views extend FULL SCREEN (behind header/footer).
//  Only the content area transitions between screens.
//

import SwiftUI

struct OnboardingShellView: View {
    @StateObject private var shellVM = OnboardingShellViewModel()
    
    var body: some View {
        ZStack {
            // LAYER 1: Full-screen content (extends behind header/footer)
            // This is the ONLY thing that transitions
            contentForCurrentStep
                .ignoresSafeArea()
            
            // LAYER 2: Fixed header overlay (always on top, never transitions)
            VStack {
                headerSection
                Spacer()
            }
            
            // LAYER 3: Fixed footer overlay (always on top, never transitions)
            VStack {
                Spacer()
                footerSection
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Fixed Header (Progress Bar + Icons) — NEVER TRANSITIONS
private extension OnboardingShellView {
    var headerSection: some View {
        VStack(spacing: 0) {
            // Top icons row — fixed-width containers to prevent layout shift
            HStack {
                // Left icon: fixed 44x44 tap target
                Button(action: {
                    if shellVM.showBackButton {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            shellVM.goToPreviousScreen()
                        }
                    } else {
                        shellVM.close()
                    }
                }) {
                    Image(systemName: shellVM.showBackButton ? "arrow.left" : "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.textSubtle)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                Spacer()
                
                // Right icon: fixed 44x44 tap target
                Button(action: {
                    if shellVM.showSkipButton {
                        shellVM.skip()
                    } else {
                        shellVM.showHelp()
                    }
                }) {
                    Group {
                        if shellVM.showSkipButton {
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
            
            // 7-Segment Progress Bar with loading animation
            ProgressIndicator(
                totalSteps: shellVM.totalSteps,
                currentStep: shellVM.currentStep,
                animatingProgress: shellVM.progressAnimationProgress
            )
            .padding(.horizontal, Theme.Spacing.xl)
            
            // Step label
            Text(shellVM.stepLabel.uppercased())
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 10)
                .foregroundColor(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.md)
        }
        // NO background — fully transparent, content shows through
    }
}

// MARK: - Content Area (FULL SCREEN — Transitions between screens)
private extension OnboardingShellView {
    @ViewBuilder
    var contentForCurrentStep: some View {
        ZStack {
            switch shellVM.currentStep {
            case 1:
                IdentityWarningContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(1)
                
            case 2:
                FailureLoopContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(2)
                
            case 3:
                UserHistoryContentView()
                    .environmentObject(shellVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(3)
                
            case 4:
                CoreDifferentiationContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(4)
            
            case 5:
                NonNegotiablesContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(5)
            
            case 6:
                CreateNonNegotiableContentView()
                    .environmentObject(shellVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(6)
            
            case 7:
                AIRegulatorContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(7)
            
            case 8:
                CommitmentAgreementContentView()
                    .environmentObject(shellVM)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(8)
            
            default:
                // Placeholder for screens 3-7
                ZStack {
                    Theme.Colors.backgroundPrimary
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Screen \(shellVM.currentStep)")
                            .font(Theme.Typography.displayLarge())
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("Coming Soon")
                            .font(Theme.Typography.bodyLarge())
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(shellVM.currentStep)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: shellVM.currentStep)
    }
}

// MARK: - Fixed Footer (CTA Button + Subtitle) — NEVER TRANSITIONS
private extension OnboardingShellView {
    var footerSection: some View {
        VStack(spacing: 0) {
            // Gradient fade from content to footer
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
            
            // CTA + subtitle
            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(
                    title: shellVM.ctaTitle,
                    showArrow: true,
                    action: {
                        shellVM.advanceToNextScreen()
                    }
                )
                .disabled(shellVM.isTransitioning || (shellVM.currentStep == 3 && !shellVM.canCompleteScreen3) || (shellVM.currentStep == 6 && !shellVM.canCompleteScreen6) || (shellVM.isLastStep && !shellVM.canCompleteFinalStep))
                .opacity((shellVM.isTransitioning || (shellVM.currentStep == 3 && !shellVM.canCompleteScreen3) || (shellVM.currentStep == 6 && !shellVM.canCompleteScreen6) || (shellVM.isLastStep && !shellVM.canCompleteFinalStep)) ? 0.5 : 1.0)
                
                Text(shellVM.ctaSubtitle.uppercased())
                    .font(Theme.Typography.captionSmall())
                    .tracking(Theme.Typography.letterSpacingWidest * 11)
                    .foregroundColor(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, 40)
            .background(Theme.Colors.backgroundPrimary)
        }
    }
}

// MARK: - Preview
struct OnboardingShellView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingShellView()
            .preferredColorScheme(.dark)
    }
}
