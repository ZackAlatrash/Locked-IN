//
//  WelcomeContentView.swift
//  LockedIn
//
//  Screen 0 — Title card. Sets tone before the identity warning.
//  Minimal by design: app name, tagline, nothing else.
//

import SwiftUI

struct WelcomeContentView: View {

    private let accentColor = Color(hex: "#22D3EE")

    @State private var nameAppeared     = false
    @State private var taglineAppeared  = false
    @State private var glowAppeared     = false

    var body: some View {
        ZStack {
            background
            glowAccent
            contentStack
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                glowAppeared = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                nameAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.65)) {
                taglineAppeared = true
            }
        }
    }
}

// MARK: - Background
private extension WelcomeContentView {
    var background: some View {
        LinearGradient(
            colors: [Color(hex: "#1A243D"), Color(hex: "#020617")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var glowAccent: some View {
        Circle()
            .fill(accentColor.opacity(glowAppeared ? 0.07 : 0))
            .frame(width: 360, height: 360)
            .blur(radius: 100)
            .offset(y: -160)
            .allowsHitTesting(false)
    }
}

// MARK: - Content
private extension WelcomeContentView {
    var contentStack: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                // App name
                Text("LOCKED IN")
                    .font(.custom("Inter", size: 46).weight(.black))
                    .tracking(6)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .opacity(nameAppeared ? 1 : 0)
                    .offset(y: nameAppeared ? 0 : 14)

                // Divider line
                Rectangle()
                    .fill(accentColor.opacity(0.35))
                    .frame(width: 32, height: 1)
                    .opacity(taglineAppeared ? 1 : 0)

                // Tagline
                Text("discipline over motivation")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(2.8)
                    .foregroundColor(Theme.Colors.textTertiary)
                    .opacity(taglineAppeared ? 1 : 0)
                    .offset(y: taglineAppeared ? 0 : 8)
            }

            Spacer()
            // Reserve space for footer CTA
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
