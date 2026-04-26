//
//  PaywallContentView.swift
//  LockedIn
//
//  "The Enforcement Layer" — paywall presented after the commitment agreement.
//  Feels like the natural next step: revealing the infrastructure that enforces
//  what the user just signed. Same visual language as the rest of onboarding —
//  navy gradient, cyan accent, document aesthetic.
//

import SwiftUI

// MARK: - Pricing Plan

private enum PricingPlan {
    case monthly, annual

    var priceLabel: String { self == .monthly ? "$7.99" : "$59.99" }
    var periodLabel: String { self == .monthly ? "/ month" : "/ year" }
    var subLabel: String {
        self == .monthly ? "cancel anytime" : "$5.00/mo billed annually"
    }
}

// MARK: - View

struct PaywallContentView: View {
    var onStartTrial: (() -> Void)?
    var onDismiss:    (() -> Void)?

    private let accentColor = Color(hex: "#22D3EE")

    @State private var heroVisible         = false
    @State private var socialProofVisible  = false
    @State private var capabilitiesVisible = false
    @State private var pricingVisible      = false
    @State private var glowPulse           = false
    @State private var dismissVisible      = false
    @State private var selectedPlan        = PricingPlan.annual

    var body: some View {
        GeometryReader { proxy in
            let hPad        = Theme.Spacing.xl
            let contentWidth = min(max(0, proxy.size.width - hPad * 2), 460)

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xxl) {
                        Spacer().frame(height: 100)

                        socialProofBar
                            .opacity(socialProofVisible ? 1 : 0)
                            .offset(y: socialProofVisible ? 0 : 10)

                        heroSection
                            .opacity(heroVisible ? 1 : 0)
                            .offset(y: heroVisible ? 0 : 12)

                        capabilitiesSection
                            .opacity(capabilitiesVisible ? 1 : 0)
                            .offset(y: capabilitiesVisible ? 0 : 12)

                        pricingSection
                            .opacity(pricingVisible ? 1 : 0)
                            .offset(y: pricingVisible ? 0 : 12)

                        Spacer().frame(height: 40)
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.bottom, Theme.Spacing.xl)
                    .frame(width: proxy.size.width)
                }
                .frame(width: proxy.size.width)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(backgroundLayer)
            .clipped()
            .overlay(alignment: .topTrailing) {
                dismissButton
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                socialProofVisible = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.10)) {
                heroVisible = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.25)) {
                capabilitiesVisible = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.40)) {
                pricingVisible = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(1.5)) {
                dismissVisible = true
            }
        }
    }
}

// MARK: - Background

private extension PaywallContentView {
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Seal glow — pulses slowly
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.07 : 0.04))
                .frame(width: 460, height: 460)
                .blur(radius: 90)
                .allowsHitTesting(false)

            // Ambient top-left glow
            Circle()
                .fill(accentColor.opacity(0.05))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -80, y: -220)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .clipped()
    }

    var dismissButton: some View {
        Button {
            onDismiss?()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(Color.white.opacity(0.25))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .padding(.trailing, Theme.Spacing.md)
        .padding(.top, 56)
        .opacity(dismissVisible ? 1 : 0)
    }
}

// MARK: - Social Proof

private extension PaywallContentView {
    var socialProofBar: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }

            Text("4.9")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white)

            Text("·")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.25))

            Text("\"I haven't skipped a session in 47 days.\"")
                .font(.custom("Inter", size: 12).italic())
                .foregroundColor(Color.white.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Hero

private extension PaywallContentView {
    var heroSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Top rule + protocol label
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)

                Text("ENFORCEMENT PROTOCOL")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.30))
                    .fixedSize()
            }

            Text("Built for people who\ndon't make excuses.")
                .font(.custom("Inter", size: 30).weight(.heavy))
                .tracking(-0.5)
                .lineSpacing(2)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            Text("Your commitment is now backed by\ninfrastructure that doesn't negotiate.")
                .font(.custom("Inter", size: 14))
                .foregroundColor(Color.white.opacity(0.45))
                .lineSpacing(4)

            // Stat anchor
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("2.4M")
                    .font(.custom("Inter", size: 28).weight(.heavy))
                    .foregroundColor(accentColor)
                Text("non-negotiables locked")
                    .font(.custom("Inter", size: 13))
                    .foregroundColor(Color.white.opacity(0.40))
            }
            .padding(.top, Theme.Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Capabilities

private extension PaywallContentView {
    struct Capability: Identifiable {
        var id   : String { index }
        let index: String
        let icon : String
        let title: String
        let sub  : String
    }

    var capabilities: [Capability] { [
        Capability(index: "01", icon: "lock.shield.fill",  title: "Non-Negotiables Lock",  sub: "Your rules can't be edited away at 2am."),
        Capability(index: "02", icon: "bolt.fill",          title: "Streak Intelligence",    sub: "You'll see a streak break coming before it happens."),
        Capability(index: "03", icon: "doc.text.fill",      title: "Emergency Protocol",     sub: "You can unlock — but you'll have to explain yourself first."),
        Capability(index: "04", icon: "chart.bar.fill",     title: "Full Insights",          sub: "See exactly where your discipline is breaking."),
    ] }

    var capabilitiesSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                ForEach(Array(capabilities.enumerated()), id: \.element.id) { idx, cap in
                    capabilityRow(cap, isLast: idx == capabilities.count - 1)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    func capabilityRow(_ cap: Capability, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.md) {
                Text(cap.index)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor.opacity(0.5))
                    .frame(width: 24, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    Image(systemName: cap.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(cap.title)
                        .font(.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(cap.sub)
                        .font(.custom("Inter", size: 12))
                        .foregroundColor(Color.white.opacity(0.40))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.vertical, Theme.Spacing.md)

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Pricing + CTA

private extension PaywallContentView {
    var pricingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Plan selector
            planSelector

            // Price display
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text(selectedPlan.priceLabel)
                        .font(.custom("Inter", size: 40).weight(.heavy))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedPlan == .annual)
                    Text(selectedPlan.periodLabel)
                        .font(.custom("Inter", size: 16))
                        .foregroundColor(Color.white.opacity(0.40))
                }
                Text(selectedPlan.subLabel)
                    .font(.custom("Inter", size: 12))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Trial timeline
            trialTimeline

            // CTA
            PrimaryButton(
                title: "LOCK IN THE TRIAL",
                showArrow: true,
                backgroundColor: accentColor,
                foregroundColor: Color(hex: "#020617"),
                action: { onStartTrial?() }
            )

            // Fine print
            Text("then $59.99/year · cancel anytime")
                .font(.custom("Inter", size: 11))
                .foregroundColor(Color.white.opacity(0.28))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Button {
                // restore purchases
            } label: {
                Text("Restore Purchases")
                    .font(.custom("Inter", size: 11).weight(.medium))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Plan Selector

    var planSelector: some View {
        HStack(spacing: Theme.Spacing.sm) {
            planPill(.monthly, label: "MONTHLY", price: "$7.99/mo")
            planPill(.annual,  label: "ANNUAL",  price: "$59.99/yr", badge: "BEST VALUE")
        }
    }

    func planPill(_ plan: PricingPlan, label: String, price: String, badge: String? = nil) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedPlan = plan
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: Theme.Spacing.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                        Text(price)
                            .font(.custom("Inter", size: 13).weight(.semibold))
                    }
                    .foregroundColor(isSelected ? Color(hex: "#020617") : Color.white.opacity(0.55))

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.10), lineWidth: 1)
                        )
                )

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(isSelected ? Color(hex: "#020617") : accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.25) : accentColor.opacity(0.18))
                        )
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Trial Timeline

    var trialTimeline: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Row 1 — labels
            HStack(spacing: 0) {
                tlLabel("TODAY",      active: true)
                Color.clear.frame(maxWidth: .infinity)
                tlLabel("DAY 7",      active: false)
                Color.clear.frame(maxWidth: .infinity)
                tlLabel("YOU DECIDE", active: false)
            }

            // Row 2 — circles + dashed connector
            ZStack {
                TrialDashLine()
                    .stroke(
                        Color.white.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )

                HStack(spacing: 0) {
                    tlCircle(filled: true)
                    Color.clear.frame(maxWidth: .infinity)
                    tlCircle(filled: false)
                    Color.clear.frame(maxWidth: .infinity)
                    tlCircle(filled: false)
                }
            }
            .frame(height: 10)

            // Row 3 — descriptions
            HStack(spacing: 0) {
                tlDesc("Full access\nunlocked",          active: true)
                Color.clear.frame(maxWidth: .infinity)
                tlDesc("Free trial\nends",               active: false)
                Color.clear.frame(maxWidth: .infinity)
                tlDesc("Keep it or walk\naway — no charge", active: false)
            }
        }
    }

    @ViewBuilder
    func tlLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1.5)
            .foregroundColor(active ? accentColor : Color.white.opacity(0.28))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    func tlCircle(filled: Bool) -> some View {
        ZStack {
            if filled {
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func tlDesc(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.custom("Inter", size: 10))
            .foregroundColor(active ? Color.white.opacity(0.50) : Color.white.opacity(0.25))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Dashed Line Shape

private struct TrialDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Preview

struct PaywallContentView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallContentView(
            onStartTrial: { print("trial") },
            onDismiss:    { print("dismiss") }
        )
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
