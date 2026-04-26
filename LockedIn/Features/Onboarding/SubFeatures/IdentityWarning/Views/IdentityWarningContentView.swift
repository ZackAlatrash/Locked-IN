//
//  IdentityWarningContentView.swift
//  LockedIn
//
//  Content-only view for Screen 1 (Identity & Warning)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Background extends edge-to-edge behind the shell's header/footer overlays
//

import SwiftUI

struct IdentityWarningContentView: View {

    private let headline       = "Locked In is "
    private let highlighted    = "not"
    private let headlineSuffix = " a habit tracker."
    private let bodyText       = "This app enforces discipline through constraints. It removes flexibility instead of adding motivation."
    private let secondaryText  = "If you want streaks, encouragement, or flexibility — this app is not for you."

    // Matches the main app's stable-state cyan accent
    private let accentColor    = Color(hex: "#22D3EE")

    // Entrance
    @State private var appeared    = false
    // Ambient glow pulse
    @State private var glowPulse   = false
    // Statue slow drift
    @State private var statueDrift = false

    var body: some View {
        ZStack {
            backgroundLayer
            refractionAccents
            contentStack
        }
        .onAppear {
            // Card entrance — slight delay so background settles first
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82).delay(0.25)) {
                appeared = true
            }
            // Glow pulse — drive with a single withAnimation, no .animation() modifier on views
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            // Statue drift — slow, subconscious
            withAnimation(.easeInOut(duration: 14.0).repeatForever(autoreverses: true)) {
                statueDrift = true
            }
        }
    }
}

// MARK: - Layout
private extension IdentityWarningContentView {
    var contentStack: some View {
        VStack {
            Spacer()
            contentCard
                .offset(y: appeared ? 0 : 28)
                .opacity(appeared ? 1 : 0)
            Spacer()
            // Reserve space for the footer CTA overlay
            Spacer().frame(height: 140)
        }
    }
}

// MARK: - Background
private extension IdentityWarningContentView {
    var backgroundLayer: some View {
        ZStack {
            // Base — matches shell background so edges blend seamlessly
            LinearGradient(
                colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Statue
            statueImage

            // Authority vignette — darkens edges, draws focus to centre
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear,                             location: 0.0),
                    .init(color: Color(hex: "#020617").opacity(0.45), location: 0.55),
                    .init(color: Color(hex: "#020617").opacity(0.90), location: 1.0)
                ]),
                center: .center,
                startRadius: 60,
                endRadius: 480
            )
        }
    }

    var statueImage: some View {
        GeometryReader { geo in
            ZStack {
                if UIImage(named: "regulator_statue") != nil {
                    Image("regulator_statue")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 1.15, height: geo.size.height * 1.15)
                        .clipped()
                } else {
                    RegulatorSilhouette()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(0.38)
            .saturation(0)
            .contrast(1.3)
            // Imperceptibly slow scale drift — feel more than see
            .scaleEffect(statueDrift ? 1.08 : 1.13)
        }
    }

    var refractionAccents: some View {
        ZStack {
            // Top-left glow — restrained, atmospheric
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.10 : 0.04))
                .frame(width: 200, height: 200)
                .blur(radius: 75)
                .offset(x: -80, y: -260)

            // Bottom-right glow
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.07 : 0.03))
                .frame(width: 170, height: 170)
                .blur(radius: 80)
                .offset(x: 100, y: 260)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Content Card
private extension IdentityWarningContentView {
    var contentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    headlineText
                    bodyTextView
                }

                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    secondaryTextView
                        .padding(.top, Theme.Spacing.md)
                }
            }
            .padding(Theme.Spacing.xxl)
        }
        // Cyan glow behind the card — ties it to the rest of the app's accent
        .shadow(color: accentColor.opacity(0.12), radius: 40, x: 0, y: 12)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    var headlineText: some View {
        Text(headlineAttributed)
            .font(.custom("Inter", size: 30).weight(.heavy))
            .tracking(-0.5)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var headlineAttributed: AttributedString {
        var base    = AttributedString(headline)
        var accent  = AttributedString(highlighted)
        var suffix  = AttributedString(headlineSuffix)
        base.foregroundColor   = UIColor(Theme.Colors.textPrimary)
        accent.foregroundColor = UIColor(accentColor)
        suffix.foregroundColor = UIColor(Theme.Colors.textPrimary)
        return base + accent + suffix
    }

    var bodyTextView: some View {
        Text(bodyText)
            .font(Theme.Typography.bodyLarge())
            .foregroundColor(Theme.Colors.textSecondary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    var secondaryTextView: some View {
        Text(secondaryText)
            .font(Theme.Typography.bodyMedium())
            .italic()
            .foregroundColor(Theme.Colors.textTertiary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Regulator Silhouette (Fallback SVG)
private struct RegulatorSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let cx = w / 2

            Path { path in
                path.addEllipse(in: CGRect(x: cx - 45, y: h * 0.12, width: 90, height: 100))
                path.addRect(CGRect(x: cx - 15, y: h * 0.22, width: 30, height: 30))
                path.move(to: CGPoint(x: cx - 100, y: h * 0.28))
                path.addQuadCurve(
                    to: CGPoint(x: cx + 100, y: h * 0.28),
                    control: CGPoint(x: cx, y: h * 0.24)
                )
                path.addLine(to: CGPoint(x: cx + 75, y: h * 0.55))
                path.addQuadCurve(
                    to: CGPoint(x: cx - 75, y: h * 0.55),
                    control: CGPoint(x: cx, y: h * 0.58)
                )
                path.closeSubpath()
                path.move(to: CGPoint(x: cx - 60, y: h * 0.55))
                path.addLine(to: CGPoint(x: cx + 60, y: h * 0.55))
                path.addLine(to: CGPoint(x: cx + 80, y: h * 0.85))
                path.addLine(to: CGPoint(x: cx - 80, y: h * 0.85))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.07),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Preview
struct IdentityWarningContentView_Previews: PreviewProvider {
    static var previews: some View {
        IdentityWarningContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
