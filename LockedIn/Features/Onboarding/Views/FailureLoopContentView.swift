//
//  FailureLoopContentView.swift
//  LockedIn
//
//  Content-only view for Screen 2 (The Failure Loop)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Background extends edge-to-edge behind the shell's header/footer overlays
//  Design sourced from Google Stitch MCP
//

import SwiftUI

struct FailureLoopContentView: View {
    
    // Screen-specific text
    private let headlineFirst = "Motivation isn't \n"
    private let headlineHighlight = "the problem"
    private let headlineSecond = "."
    private let footerText = "Planning is easy. Follow-through breaks when everything stays optional."
    
    // The failure loop steps (SF Symbol names directly)
    private let loopSteps: [LoopStep] = [
        LoopStep(icon: "paperplane.fill", label: "Ambition", isHighlighted: false, textStyle: .secondary),
        LoopStep(icon: "calendar.badge.plus", label: "Overcommitment", isHighlighted: true, textStyle: .primary),
        LoopStep(icon: "link", label: "Missed day", isHighlighted: false, textStyle: .tertiary),
        LoopStep(icon: "face.dashed", label: "Shame", isHighlighted: false, textStyle: .tertiary),
        LoopStep(icon: "door.left.hand.open", label: "Quit", isHighlighted: false, textStyle: .tertiary)
    ]
    
    var body: some View {
        ZStack {
            // Full-screen background
            Theme.Colors.backgroundPrimary
            
            // Background accent icon
            backgroundAccent
            
            // Glass refraction accents
            refractionAccents
            
            // Content — vertically centered with space for header/footer overlays
            VStack(spacing: 0) {
                // Space for header overlay — push content toward center
                Spacer().frame(height: 180)
                
                // Headline
                headlineSection
                
                Spacer(minLength: Theme.Spacing.md)
                
                // Timeline inside GlassCard
                timelineCard
                
                Spacer(minLength: Theme.Spacing.sm)
                
                // Footer text
                footerTextSection
                
                Spacer(minLength: Theme.Spacing.xs)
                
                // Space for CTA button overlay
                Spacer().frame(height: 160)
            }
        }
    }
}

// MARK: - Loop Step Model
extension FailureLoopContentView {
    struct LoopStep: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let isHighlighted: Bool
        let textStyle: TextStyle
        
        enum TextStyle {
            case primary, secondary, tertiary
        }
    }
}

// MARK: - Background
private extension FailureLoopContentView {
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

// MARK: - Headline
private extension FailureLoopContentView {
    var headlineSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            (
                Text(headlineFirst)
                    .foregroundColor(Theme.Colors.textPrimary)
                +
                Text(headlineHighlight)
                    .foregroundColor(Theme.Colors.authority)
                +
                Text(headlineSecond)
                    .foregroundColor(Theme.Colors.textPrimary)
            )
            .font(.system(size: 30, weight: .heavy))
            .tracking(-0.5)
            .lineSpacing(2)
            .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Timeline Card
private extension FailureLoopContentView {
    var timelineCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                ForEach(Array(loopSteps.enumerated()), id: \.element.id) { index, step in
                    loopStepRow(step: step, isLast: index == loopSteps.count - 1)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }
    
    func loopStepRow(step: LoopStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(spacing: 2) {
                stepIcon(step: step)
                if !isLast {
                    connectorLine
                }
            }
            
            Text(step.label)
                .font(.system(size: 15, weight: step.isHighlighted ? .bold : .medium))
                .foregroundColor(textColor(for: step.textStyle))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)
        }
    }
    
    func stepIcon(step: LoopStep) -> some View {
        ZStack {
            Circle()
                .fill(step.isHighlighted ? Theme.Colors.authority : Color(hex: "#161616"))
                .frame(width: 36, height: 36)
            
            if !step.isHighlighted {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    .frame(width: 36, height: 36)
            }
            
            Image(systemName: step.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(step.isHighlighted ? Theme.Colors.textPrimary : iconColor(for: step.textStyle))
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
    
    func textColor(for style: LoopStep.TextStyle) -> Color {
        switch style {
        case .primary: return Theme.Colors.textPrimary
        case .secondary: return Theme.Colors.textTertiary
        case .tertiary: return Theme.Colors.textSubtle
        }
    }
    
    func iconColor(for style: LoopStep.TextStyle) -> Color {
        switch style {
        case .primary: return Theme.Colors.textPrimary
        case .secondary: return Theme.Colors.textTertiary
        case .tertiary: return Theme.Colors.textSubtle
        }
    }
}

// MARK: - Footer Text
private extension FailureLoopContentView {
    var footerTextSection: some View {
        Text(footerText)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Theme.Colors.textTertiary)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xxl)
    }
}

// MARK: - Preview
struct FailureLoopContentView_Previews: PreviewProvider {
    static var previews: some View {
        FailureLoopContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
