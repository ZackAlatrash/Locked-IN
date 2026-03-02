//
//  GlassCard.swift
//  LockedIn
//
//  Reusable liquid glassmorphism card component
//  Design sourced from Google Stitch MCP
//
//  Stitch CSS:
//    backdrop-filter: blur(20px) saturate(180%);
//    background-color: rgba(15, 8, 8, 0.65);
//    border: 1px solid rgba(255, 255, 255, 0.08);
//    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.8);
//    border-radius: 0.75rem (rounded-xl)
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                ZStack {
                    // Blur backdrop simulation
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(Color(hex: "#0f0808").opacity(0.65))
                    
                    // Subtle highlight gradient at top
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.8),
                radius: 32,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Preview
struct GlassCard_Previews: PreviewProvider {
    static var previews: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.md) {
                Text("Glass Card")
                    .font(Theme.Typography.headlineLarge())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("This is a glassmorphism card component.")
                    .font(Theme.Typography.bodyLarge())
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.xxl)
        }
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.backgroundPrimary)
        .previewLayout(.sizeThatFits)
    }
}
