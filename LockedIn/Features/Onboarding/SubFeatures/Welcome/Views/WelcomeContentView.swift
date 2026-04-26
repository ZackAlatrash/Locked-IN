//
//  WelcomeContentView.swift
//  LockedIn
//
//  Screen 0 — Initiation. Sets the tone before the identity warning.
//  A seal mark anchors the eye. The atmosphere matches the rest of onboarding.
//  Minimal copy, but with a value proposition that answers "what is this?"
//

import SwiftUI

struct WelcomeContentView: View {

    private let accentColor = Color(hex: "#22D3EE")

    @State private var glowPulse       = false
    @State private var sealAppeared    = false
    @State private var sealPulse       = false
    @State private var nameAppeared    = false
    @State private var taglineAppeared = false
    @State private var subtitleAppeared = false

    var body: some View {
        ZStack {
            backgroundLayer
            contentStack
        }
        .onAppear {
            // Background atmosphere — immediately, forever
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            // Seal rings entrance — immediately
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                sealAppeared = true
            }
            // Seal breathing — starts after entrance settles
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
                sealPulse = true
            }
            // App name — 0.2s
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.2)) {
                nameAppeared = true
            }
            // Divider + tagline — 0.4s
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                taglineAppeared = true
            }
            // Value prop subtitle — 0.6s
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                subtitleAppeared = true
            }
        }
    }
}

// MARK: - Background

private extension WelcomeContentView {
    var backgroundLayer: some View {
        ZStack {
            // Base gradient — identical to all other onboarding screens
            LinearGradient(
                colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Top-left glow
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.08 : 0.03))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: -90, y: -230)
                .allowsHitTesting(false)

            // Bottom-right glow
            Circle()
                .fill(accentColor.opacity(glowPulse ? 0.05 : 0.02))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 110, y: 260)
                .allowsHitTesting(false)

            // Background decorative icon — barely visible, adds texture
            Image(systemName: "lock.fill")
                .font(.system(size: 130, weight: .regular))
                .foregroundColor(accentColor.opacity(0.035))
                .rotationEffect(.degrees(-10))
                .offset(x: 70, y: -110)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Seal Mark

private extension WelcomeContentView {
    var sealMark: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
                .frame(width: 148, height: 148)

            // Inner ring
            Circle()
                .stroke(accentColor.opacity(0.18), lineWidth: 0.5)
                .frame(width: 100, height: 100)

            // Center dot
            Circle()
                .fill(accentColor.opacity(0.40))
                .frame(width: 7, height: 7)
        }
        .scaleEffect(sealPulse ? 1.015 : 1.0)
        .scaleEffect(sealAppeared ? 1.0 : 0.82)
        .opacity(sealAppeared ? 1 : 0)
    }
}

// MARK: - Content

private extension WelcomeContentView {
    var contentStack: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Seal mark — the visual anchor
                sealMark

                Spacer().frame(height: 28)

                // Small protocol label above the app name
                Text("ENFORCEMENT SYSTEM · V1")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .tracking(2.5)
                    .foregroundColor(Color.white.opacity(0.18))
                    .opacity(nameAppeared ? 1 : 0)

                Spacer().frame(height: 8)

                // App name
                Text("LOCKED IN")
                    .font(.custom("Inter", size: 42).weight(.black))
                    .tracking(6)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .shadow(color: accentColor.opacity(0.12), radius: 20, x: 0, y: 0)
                    .opacity(nameAppeared ? 1 : 0)
                    .offset(y: nameAppeared ? 0 : 14)

                Spacer().frame(height: 20)

                // Divider
                Rectangle()
                    .fill(accentColor.opacity(0.30))
                    .frame(width: 40, height: 1)
                    .opacity(taglineAppeared ? 1 : 0)

                Spacer().frame(height: 14)

                // Tagline
                Text("discipline over motivation")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(2.8)
                    .foregroundColor(Color.white.opacity(0.38))
                    .opacity(taglineAppeared ? 1 : 0)
                    .offset(y: taglineAppeared ? 0 : 8)

                Spacer().frame(height: 10)

                // Value proposition
                Text("Your rules. Sealed. No exceptions.")
                    .font(.custom("Inter", size: 12))
                    .tracking(0.5)
                    .foregroundColor(Color.white.opacity(0.24))
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 6)
            }

            Spacer()

            // Reserve space for the footer CTA overlay
            Spacer().frame(height: 140)
        }
    }
}

// MARK: - Preview

struct WelcomeContentView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
