//
//  FailureLoopContentView.swift
//  LockedIn
//
//  Screen 3 — The Failure Loop
//  Each step animates in sequentially so the user watches the familiar spiral
//  play out: Ambition → Overcommitment → Missed day → Shame → Quit.
//  Visual language matches the rest of the onboarding (navy gradient, glass card).
//

import SwiftUI

struct FailureLoopContentView: View {

    private let accentColor = Color(hex: "#22D3EE")

    private let loopSteps: [LoopStep] = [
        LoopStep(icon: "paperplane.fill",       label: "Ambition",        style: .ambition),
        LoopStep(icon: "calendar.badge.plus",   label: "Overcommitment",  style: .overcommit),
        LoopStep(icon: "link",                  label: "Missed day",      style: .fade),
        LoopStep(icon: "face.dashed",           label: "Shame",           style: .fade),
        LoopStep(icon: "door.left.hand.open",   label: "Quit",            style: .quit)
    ]

    @State private var headlineVisible  = false
    @State private var stepVisible      = [false, false, false, false, false]
    @State private var connectorVisible = [false, false, false, false]
    @State private var footerVisible    = false
    @State private var overcommitPulse  = false
    @State private var glowPulse        = false

    var body: some View {
        ZStack {
            backgroundLayer
            refractionAccents
            contentStack
        }
        .onAppear {
            startAnimations()
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Step Model

extension FailureLoopContentView {
    struct LoopStep: Identifiable {
        let id    = UUID()
        let icon  : String
        let label : String
        let style : StepStyle

        enum StepStyle {
            case ambition    // cyan — the hopeful start
            case overcommit  // authority red — where it breaks
            case fade        // dim — the decline
            case quit        // dark end
        }
    }
}

// MARK: - Animation Sequence

private extension FailureLoopContentView {
    func startAnimations() {
        func after(_ delay: Double, _ work: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }

        // Headline
        after(0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                headlineVisible = true
            }
        }

        // Steps — staggered reveal
        let base: Double = 0.55
        let gap:  Double = 0.38

        for i in 0..<5 {
            let t = base + Double(i) * gap
            after(t) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    stepVisible[i] = true
                }
            }
            if i < 4 {
                // Connector draws down shortly after the step above it settles
                after(t + 0.18) {
                    withAnimation(.easeOut(duration: 0.28)) {
                        connectorVisible[i] = true
                    }
                }
            }
        }

        // Overcommitment pulse — fires after step[1] settles
        let overcommitBeat = base + gap + 0.45
        after(overcommitBeat) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                overcommitPulse = true
            }
            after(0.45) {
                withAnimation(.easeOut(duration: 0.55)) {
                    overcommitPulse = false
                }
            }
        }

        // Footer — after last step lands
        after(base + 4.0 * gap + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) { footerVisible = true }
        }
    }
}

// MARK: - Background

private extension FailureLoopContentView {
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Atmospheric background icon — faint, does not compete with content
            Image(systemName: "eye.fill")
                .font(.system(size: 130, weight: .regular))
                .foregroundColor(accentColor.opacity(0.06))
                .rotationEffect(.degrees(12))
                .offset(x: 80, y: -170)
                .allowsHitTesting(false)
        }
    }

    var refractionAccents: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.08 : 0.03))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: -100, y: -220)

            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.05 : 0.02))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 110, y: 260)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Content

private extension FailureLoopContentView {
    var contentStack: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 150)

            headlineSection
                .opacity(headlineVisible ? 1 : 0)
                .offset(y: headlineVisible ? 0 : 10)

            Spacer(minLength: Theme.Spacing.sm)

            timelineCard

            Spacer(minLength: Theme.Spacing.sm)

            footerSection
                .opacity(footerVisible ? 1 : 0)

            Spacer().frame(height: 130)
        }
    }

    // MARK: Headline

    var headlineSection: some View {
        Text(headlineAttributed)
            .font(.custom("Inter", size: 30).weight(.heavy))
            .tracking(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var headlineAttributed: AttributedString {
        var part1  = AttributedString("Motivation isn't ")
        var part2  = AttributedString("the problem")
        var part3  = AttributedString(".")
        part1.foregroundColor = UIColor(Theme.Colors.textPrimary)
        part2.foregroundColor = UIColor(accentColor)
        part3.foregroundColor = UIColor(Theme.Colors.textPrimary)
        return part1 + part2 + part3
    }

    // MARK: Timeline Card
    // All rows live in the hierarchy from the start so the card holds its size.
    // Each row animates from invisible to visible — the card never resizes.

    var timelineCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                ForEach(Array(loopSteps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step, index: index, isLast: index == loopSteps.count - 1)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: Footer

    var footerSection: some View {
        Text("Planning is easy. Follow-through breaks when everything stays optional.")
            .font(.custom("Inter", size: 14).weight(.medium))
            .foregroundColor(Color.white.opacity(0.55))
            .lineSpacing(5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xl)
    }
}

// MARK: - Step Row

private extension FailureLoopContentView {
    func stepRow(_ step: LoopStep, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Icon column — fixed width keeps labels aligned
            VStack(spacing: 0) {
                stepIcon(step, index: index)
                if !isLast {
                    connectorLine(index: index)
                }
            }
            .frame(width: 38)

            Text(step.label)
                .font(.custom("Inter", size: 15).weight(step.style == .overcommit ? .bold : .medium))
                .foregroundColor(labelColor(for: step.style))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 9)
                .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)
        }
        // Slide in from left + fade
        .opacity(stepVisible[index] ? 1 : 0)
        .offset(x: stepVisible[index] ? 0 : -14)
    }

    func stepIcon(_ step: LoopStep, index: Int) -> some View {
        ZStack {
            Circle()
                .fill(iconBackground(for: step.style))
                .frame(width: 38, height: 38)

            if step.style != .overcommit {
                Circle()
                    .stroke(iconBorder(for: step.style), lineWidth: 1)
                    .frame(width: 38, height: 38)
            }

            Image(systemName: step.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(iconForeground(for: step.style))
        }
        // Overcommitment gets a spring-pop glow beat
        .scaleEffect(step.style == .overcommit && overcommitPulse ? 1.15 : 1.0)
        .shadow(
            color: shadowColor(for: step.style),
            radius: step.style == .overcommit ? (overcommitPulse ? 18 : 10) : 7
        )
    }

    func connectorLine(index: Int) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.white.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: 26)
            // Draws downward from the step above
            .scaleEffect(y: connectorVisible[index] ? 1 : 0, anchor: .top)
    }
}

// MARK: - Style Helpers

private extension FailureLoopContentView {
    func iconBackground(for style: LoopStep.StepStyle) -> Color {
        switch style {
        case .ambition:   return Color.white.opacity(0.05)
        case .overcommit: return accentColor.opacity(0.25)
        case .fade:       return Color.white.opacity(0.05)
        case .quit:       return accentColor.opacity(0.08)
        }
    }

    func iconBorder(for style: LoopStep.StepStyle) -> Color {
        switch style {
        case .ambition:   return Color.white.opacity(0.08)
        case .overcommit: return accentColor.opacity(0.5)
        case .fade:       return Color.white.opacity(0.08)
        case .quit:       return accentColor.opacity(0.18)
        }
    }

    func iconForeground(for style: LoopStep.StepStyle) -> Color {
        switch style {
        case .ambition:   return Color.white.opacity(0.5)
        case .overcommit: return accentColor
        case .fade:       return Color.white.opacity(0.35)
        case .quit:       return accentColor.opacity(0.45)
        }
    }

    func labelColor(for style: LoopStep.StepStyle) -> Color {
        switch style {
        case .ambition:   return Color.white.opacity(0.6)
        case .overcommit: return Color.white
        case .fade:       return Color.white.opacity(0.4)
        case .quit:       return Color.white.opacity(0.25)
        }
    }

    func shadowColor(for style: LoopStep.StepStyle) -> Color {
        switch style {
        case .overcommit: return accentColor.opacity(overcommitPulse ? 0.60 : 0.25)
        default:          return .clear
        }
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
