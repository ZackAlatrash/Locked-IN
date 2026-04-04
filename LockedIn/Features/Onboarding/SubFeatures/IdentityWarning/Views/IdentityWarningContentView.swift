//
//  IdentityWarningContentView.swift
//  LockedIn
//
//  Content-only view for Screen 1 (Identity & Warning)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Background extends edge-to-edge behind the shell's header/footer overlays
//  Design sourced from Google Stitch MCP
//

import SwiftUI

struct IdentityWarningContentView: View {
    
    // Screen-specific text
    private let headline = "Locked In is "
    private let highlightedWord = "not"
    private let headlineSuffix = " a habit tracker."
    private let bodyText = "This app enforces discipline through constraints. It removes flexibility instead of adding motivation."
    private let secondaryText = "If you want streaks, encouragement, or flexibility — this app is not for you."
    
    var body: some View {
        ZStack {
            // Full-screen background: statue + gradient
            backgroundLayer
            
            // Glass refraction accents
            refractionAccents
            
            // Content card centered vertically
            VStack {
                Spacer()
                contentCard
                Spacer()
                // Extra space at bottom for the CTA button overlay
                Spacer().frame(height: 120)
            }
        }
    }
}

// MARK: - Background Layer (Full Screen)
private extension IdentityWarningContentView {
    var backgroundLayer: some View {
        ZStack {
            // Base background
            Theme.Colors.backgroundPrimary
            
            // Statue image
            statueImage
            
            // Radial gradient overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color(hex: "#0a0505").opacity(0.6),
                    Color(hex: "#0a0505")
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
        }
    }
    
    var statueImage: some View {
        GeometryReader { geo in
            ZStack {
                if let _ = UIImage(named: "regulator_statue") {
                    Image("regulator_statue")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 1.1, height: geo.size.height * 1.1)
                        .clipped()
                } else {
                    RegulatorSilhouette()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(0.40)
            .saturation(0)
            .contrast(1.25)
            .scaleEffect(1.10)
        }
    }
    
    var refractionAccents: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: -100, y: -240)
            
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 100, y: 240)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Content Card
private extension IdentityWarningContentView {
    var contentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Headline + body
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    headlineText
                    bodyTextView
                }
                
                // Separator + secondary
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    secondaryTextView
                        .padding(.top, Theme.Spacing.md)
                }
            }
            .padding(Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }
    
    var headlineText: some View {
        HStack(spacing: 0) {
            Text(headline)
                .foregroundColor(Theme.Colors.textPrimary)
            Text(highlightedWord)
                .foregroundColor(Theme.Colors.authority)
            Text(headlineSuffix)
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .font(.custom("Inter", size: 30).weight(.heavy))
        .tracking(-0.5)
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
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
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Regulator Silhouette (Fallback)
private struct RegulatorSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            
            ZStack {
                Path { path in
                    path.addEllipse(in: CGRect(
                        x: centerX - 45, y: height * 0.12,
                        width: 90, height: 100
                    ))
                    path.addRect(CGRect(
                        x: centerX - 15, y: height * 0.22,
                        width: 30, height: 30
                    ))
                    path.move(to: CGPoint(x: centerX - 100, y: height * 0.28))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 100, y: height * 0.28),
                        control: CGPoint(x: centerX, y: height * 0.24)
                    )
                    path.addLine(to: CGPoint(x: centerX + 75, y: height * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 75, y: height * 0.55),
                        control: CGPoint(x: centerX, y: height * 0.58)
                    )
                    path.closeSubpath()
                    path.move(to: CGPoint(x: centerX - 60, y: height * 0.55))
                    path.addLine(to: CGPoint(x: centerX + 60, y: height * 0.55))
                    path.addLine(to: CGPoint(x: centerX + 80, y: height * 0.85))
                    path.addLine(to: CGPoint(x: centerX - 80, y: height * 0.85))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
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
