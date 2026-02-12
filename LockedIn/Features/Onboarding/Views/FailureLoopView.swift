//
//  FailureLoopView.swift
//  LockedIn
//
//  The Failure Loop onboarding screen (Screen 2 of 7)
//  Design sourced from Google Stitch MCP
//
//  Layout structure:
//    - Background: dark with subtle visibility icon accent + refraction accents
//    - Header (FIXED): back/skip icons + 7-segment ProgressIndicator + step label
//    - Content (fills remaining space): headline + GlassCard timeline + footer text
//    - Footer (FIXED): PrimaryButton + subtitle
//

import SwiftUI

struct FailureLoopView: View {
    @StateObject private var viewModel: FailureLoopViewModel
    
    init(onContinue: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: FailureLoopViewModel(onContinue: onContinue))
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            // Background accent icon (visibility eye)
            backgroundAccent
            
            // Glass refraction accents
            refractionAccents
            
            // Main layout: fixed header, flexible content, fixed footer
            VStack(spacing: 0) {
                // FIXED Header: back/skip + progress bar + step label
                headerSection
                
                // Content: fills remaining space between header and footer
                // No scrolling — everything fits on one screen
                VStack(spacing: 0) {
                    Spacer(minLength: Theme.Spacing.md)
                    
                    // Headline
                    headlineSection
                    
                    Spacer(minLength: Theme.Spacing.md)
                    
                    // Failure loop timeline inside GlassCard
                    timelineCard
                    
                    Spacer(minLength: Theme.Spacing.sm)
                    
                    // Footer text
                    footerTextSection
                    
                    Spacer(minLength: Theme.Spacing.md)
                }
                
                // FIXED Footer: CTA button + subtitle
                footerSection
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Background Accent
private extension FailureLoopView {
    var backgroundAccent: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "eye.fill")
                    .font(.system(size: 140, weight: .regular))
                    .foregroundColor(Theme.Colors.authority.opacity(0.08))
                    .rotationEffect(.degrees(12))
                    .offset(x: 20, y: 0)
            }
            Spacer()
        }
        .padding(.top, 40)
        .allowsHitTesting(false)
    }
    
    var refractionAccents: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: -100, y: -UIScreen.main.bounds.height * 0.25)
            
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 100, y: UIScreen.main.bounds.height * 0.25)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Header Section (FIXED — SAME as Screen 1)
private extension FailureLoopView {
    var headerSection: some View {
        VStack(spacing: 0) {
            // Top icons row
            HStack {
                Button(action: viewModel.didTapBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.textSubtle)
                }
                
                Spacer()
                
                Button(action: viewModel.didTapSkip) {
                    Text("Skip")
                        .font(Theme.Typography.bodyMedium())
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textSubtle)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, 60)
            .padding(.bottom, Theme.Spacing.xl)
            
            // 7-Segment Progress Bar — EXACT SAME as Screen 1
            ProgressIndicator(
                totalSteps: viewModel.totalSteps,
                currentStep: viewModel.currentStep
            )
            .padding(.horizontal, Theme.Spacing.xl)
            
            // Step label — EXACT SAME as Screen 1
            Text(viewModel.stepLabel.uppercased())
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 10)
                .foregroundColor(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
        }
    }
}

// MARK: - Headline Section
private extension FailureLoopView {
    var headlineSection: some View {
        (
            Text(viewModel.headline)
                .foregroundColor(Theme.Colors.textPrimary)
            +
            Text(viewModel.highlightedWord)
                .foregroundColor(Theme.Colors.authority)
            +
            Text(viewModel.headlineSuffix)
                .foregroundColor(Theme.Colors.textPrimary)
        )
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.5)
        .lineSpacing(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.xl)
    }
}

// MARK: - Timeline Card (GlassCard wrapping the failure loop)
private extension FailureLoopView {
    var timelineCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.loopSteps.enumerated()), id: \.element.id) { index, step in
                    loopStepRow(step: step, isLast: index == viewModel.loopSteps.count - 1)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }
    
    func loopStepRow(step: FailureLoopViewModel.LoopStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Icon column with connector line
            VStack(spacing: 2) {
                stepIcon(step: step)
                
                if !isLast {
                    connectorLine
                }
            }
            
            // Label
            Text(step.label)
                .font(.system(size: 15, weight: step.isHighlighted ? .bold : .medium))
                .foregroundColor(textColor(for: step.textColor))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)
        }
    }
    
    func stepIcon(step: FailureLoopViewModel.LoopStep) -> some View {
        ZStack {
            Circle()
                .fill(step.isHighlighted ? Theme.Colors.authority : Color(hex: "#161616"))
                .frame(width: 36, height: 36)
            
            if !step.isHighlighted {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    .frame(width: 36, height: 36)
            }
            
            Image(systemName: sfSymbol(for: step.icon))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(step.isHighlighted ? Theme.Colors.textPrimary : iconColor(for: step.textColor))
        }
        .scaleEffect(step.isHighlighted ? 1.1 : 1.0)
        .shadow(
            color: step.isHighlighted ? Theme.Colors.authority.opacity(0.3) : .clear,
            radius: step.isHighlighted ? 12 : 0
        )
    }
    
    var connectorLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.20),
                        Color.white.opacity(0.10)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: 24)
    }
    
    func textColor(for style: FailureLoopViewModel.LoopStep.TextColorStyle) -> Color {
        switch style {
        case .primary:
            return Theme.Colors.textPrimary
        case .secondary:
            return Theme.Colors.textTertiary
        case .tertiary:
            return Theme.Colors.textSubtle
        }
    }
    
    func iconColor(for style: FailureLoopViewModel.LoopStep.TextColorStyle) -> Color {
        switch style {
        case .primary:
            return Theme.Colors.textPrimary
        case .secondary:
            return Theme.Colors.textTertiary
        case .tertiary:
            return Theme.Colors.textSubtle
        }
    }
    
    func sfSymbol(for materialIcon: String) -> String {
        switch materialIcon {
        case "rocket_launch":
            return "paperplane.fill"
        case "edit_calendar":
            return "calendar.badge.plus"
        case "link_off":
            return "link"
        case "sentiment_dissatisfied":
            return "face.dashed"
        case "door_open":
            return "door.left.hand.open"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Footer Text Section
private extension FailureLoopView {
    var footerTextSection: some View {
        Text(viewModel.footerText)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Theme.Colors.textTertiary)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xxl)
    }
}

// MARK: - Footer Section (FIXED — SAME as Screen 1)
private extension FailureLoopView {
    var footerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // CTA Button — EXACT SAME PrimaryButton as Screen 1
            PrimaryButton(
                title: viewModel.ctaTitle,
                showArrow: true,
                action: viewModel.didTapContinue
            )
            
            // Subtitle — EXACT SAME style as Screen 1
            Text(viewModel.ctaSubtitle.uppercased())
                .font(Theme.Typography.captionSmall())
                .tracking(Theme.Typography.letterSpacingWidest * 11)
                .foregroundColor(Theme.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.bottom, 40)
    }
}

// MARK: - Preview
struct FailureLoopView_Previews: PreviewProvider {
    static var previews: some View {
        FailureLoopView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
