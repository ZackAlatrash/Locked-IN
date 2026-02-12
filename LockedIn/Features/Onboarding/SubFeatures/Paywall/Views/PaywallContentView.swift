//
//  PaywallContentView.swift
//  LockedIn
//
//  Standalone Paywall screen with blue/green theme
//  Appears after onboarding completion
//

import SwiftUI

struct PaywallContentView: View {
    // Callback for when user starts trial or dismisses
    var onStartTrial: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    // Blue/Green theme colors
    private let accentBlue = Color(hex: "00D4FF")
    private let accentGreen = Color(hex: "00FF88")
    private let gradientStart = Color(hex: "0066FF")
    private let gradientEnd = Color(hex: "00CC88")
    
    // Screen-specific text
    private let headline = "Unlock Your Full Potential"
    private let subheadline = "Join thousands who have transformed their discipline with Locked In Premium."
    
    // Features list
    private let features = [
        "Unlimited deep work protocols",
        "Advanced biometric habit security",
        "Full data visualization & insights",
        "Priority AI coaching access"
    ]
    
    var body: some View {
        ZStack {
            // Full-screen dark background
            backgroundLayer
            
            // Decorative glow effects
            decorativeGlows
            
            // Main content
            VStack {
                // Dismiss button
                HStack {
                    Spacer()
                    Button(action: {
                        onDismiss?()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .padding(.trailing, Theme.Spacing.xl)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Liquid Glass Card
                liquidGlassCard
                    .padding(.horizontal, Theme.Spacing.xl)
                
                Spacer()
            }
        }
    }
}

// MARK: - Background Layer
private extension PaywallContentView {
    var backgroundLayer: some View {
        ZStack {
            // Base dark background
            Theme.Colors.backgroundPrimary
            
            // Dashboard preview gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.backgroundPrimary.opacity(0.6),
                    Theme.Colors.backgroundPrimary.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle grid pattern effect (simulated with lines)
            VStack(spacing: 40) {
                ForEach(0..<8) { _ in
                    HStack(spacing: 40) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 60, height: 40)
                        }
                    }
                }
            }
            .opacity(0.5)
            .rotationEffect(.degrees(-5))
        }
    }
    
    var decorativeGlows: some View {
        ZStack {
            // Top right blue glow
            Circle()
                .fill(accentBlue.opacity(0.2))
                .frame(width: 350, height: 350)
                .blur(radius: 120)
                .offset(x: 120, y: -180)
            
            // Bottom left green glow
            Circle()
                .fill(accentGreen.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -180, y: 250)
            
            // Center subtle gradient glow
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [accentBlue, accentGreen]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.1)
                )
                .frame(width: 500, height: 500)
                .blur(radius: 150)
                .offset(y: 50)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Liquid Glass Card
private extension PaywallContentView {
    var liquidGlassCard: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Header Section
            headerSection
            
            // Features List
            featuresSection
            
            // CTA Section
            ctaSection
        }
        .padding(Theme.Spacing.xxl)
        .background(
            // Liquid glass effect
            ZStack {
                // Base glass background
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.glassBackground)
                
                // Subtle gradient overlay for depth
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.05),
                                Color.clear,
                                Color.black.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(Theme.Colors.glassBorder, lineWidth: 1)
            }
        )
        .shadow(
            color: Color.black.opacity(0.4),
            radius: 32,
            x: 0,
            y: 8
        )
    }
    
    var headerSection: some View {
        VStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Premium badge with gradient
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(accentGreen)
                
                Text("PREMIUM ACCESS")
                    .font(Theme.Typography.caption())
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [accentBlue, accentGreen]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
            )
            
            // Headline with gradient
            Text(headline)
                .font(.custom("Inter", size: 32).weight(.black))
                .tracking(-0.5)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, accentBlue.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
            
            // Subheadline
            Text(subheadline)
                .font(Theme.Typography.bodyLarge())
                .foregroundColor(Theme.Colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    var featuresSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Divider()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentBlue.opacity(0.3), accentGreen.opacity(0.3)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ForEach(features, id: \.self) { feature in
                HStack(spacing: Theme.Spacing.sm) {
                    // Checkmark with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [accentBlue.opacity(0.3), accentGreen.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentGreen)
                    }
                    
                    Text(feature)
                        .font(Theme.Typography.bodyMedium())
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.textPrimary.opacity(0.9))
                    
                    Spacer()
                }
            }
            
            Divider()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentBlue.opacity(0.3), accentGreen.opacity(0.3)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
    
    var ctaSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Trial button with blue/green gradient
            Button(action: {
                onStartTrial?()
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.white)
                    
                    Text("START FREE TRIAL")
                        .font(Theme.Typography.buttonLarge())
                        .fontWeight(.bold)
                        .tracking(Theme.Typography.letterSpacingWide * 12)
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                    
                    Spacer(minLength: 16)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .padding(.horizontal, Theme.Spacing.xxl)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [gradientStart, gradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Theme.CornerRadius.sm)
                .shadow(
                    color: accentBlue.opacity(0.4),
                    radius: 24,
                    x: 0,
                    y: 12
                )
            }
            .buttonStyle(PaywallButtonStyle())
            
            // Pricing info
            VStack(spacing: Theme.Spacing.xxs) {
                Text("7-day free trial, then $59.99/year")
                    .font(Theme.Typography.bodyMedium())
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text("Cancel anytime. No commitment required.")
                    .font(Theme.Typography.captionSmall())
                    .foregroundColor(Theme.Colors.textMuted)
            }
            .multilineTextAlignment(.center)
            
            // Restore purchases link
            Button(action: {
                // Restore purchases action
            }) {
                Text("Restore Purchases")
                    .font(Theme.Typography.caption())
                    .foregroundColor(accentBlue)
                    .underline()
            }
        }
    }
}

// MARK: - Button Style
private struct PaywallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                .easeInOut(duration: Theme.Animation.defaultDuration),
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview
struct PaywallContentView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallContentView(
            onStartTrial: { print("Start trial tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
