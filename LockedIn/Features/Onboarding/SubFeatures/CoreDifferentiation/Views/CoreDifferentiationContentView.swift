//
//  CoreDifferentiationContentView.swift
//  LockedIn
//
//  Content-only view for Screen 3 (Core Differentiation)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Design sourced from Google Stitch MCP — EXACT MATCH
//

import SwiftUI

struct CoreDifferentiationContentView: View {
    
    var body: some View {
        ZStack {
            // Full-screen background
            Theme.Colors.backgroundPrimary
            
            // Main content — compact, no scroll
            VStack(spacing: 0) {
                // Space for header overlay — push content toward center
                Spacer().frame(height: 180)
                
                // Headline & Body
                headlineSection
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.lg)
                
                // Comparison Diagram (2 columns) — compact height
                comparisonDiagram
                    .padding(.bottom, Theme.Spacing.lg)
                
                // Descriptive list below diagram
                descriptiveList
                
                Spacer()
                
                // Space for CTA button
                Spacer().frame(height: 160)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

}

// MARK: - Headline Section
private extension CoreDifferentiationContentView {
    var headlineSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Headline: "Locked In removes negotiation."
            (
                Text("Locked In removes\n")
                    .foregroundColor(Theme.Colors.textPrimary)
                +
                Text("negotiation.")
                    .foregroundColor(Theme.Colors.authority)
                    .italic()
            )
            .font(.system(size: 30, weight: .heavy))
            .tracking(-0.5)
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            
            // Body text
            Text("You commit to a small number of non-negotiables. The system locks them in place.")
                .font(Theme.Typography.bodyLarge())
                .foregroundColor(Theme.Colors.textSecondary)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
    }
}

// MARK: - Comparison Diagram
private extension CoreDifferentiationContentView {
    var comparisonDiagram: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left: Traditional Tracker (Flexible/Blurry)
            traditionalTrackerCard
                .frame(maxWidth: .infinity)
            
            // Right: Locked In (Solid/Heavy)
            lockedInCard
                .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
    }
    
    var traditionalTrackerCard: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Label
            Text("TRADITIONAL TRACKER")
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 6)
                .foregroundColor(Theme.Colors.textMuted)
            
            // Card content
            ZStack {
                // Liquid glass background (blurry, faded)
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Color.white.opacity(0.03))
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                
                VStack(spacing: Theme.Spacing.xs) {
                    // Header with history icon
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 4)
                        
                        Spacer()
                    }
                    .opacity(0.4)
                    
                    // Flexible items (blurry) — all 3 items
                    VStack(spacing: Theme.Spacing.xxs) {
                        flexibleItem(blur: 1, width: 36, icon: "pencil")
                        flexibleItem(blur: 2, width: 48, icon: "xmark")
                        flexibleItem(blur: 1, width: 28, icon: "ellipsis")
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Add button
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.1))
                        )
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
            }
            .opacity(0.6)
        }
    }
    
    func flexibleItem(blur: CGFloat, width: CGFloat, icon: String) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: width, height: 6)
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .blur(radius: blur)
    }
    
    var lockedInCard: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Label
            Text("LOCKED IN")
                .font(Theme.Typography.caption())
                .tracking(Theme.Typography.letterSpacingWidest * 6)
                .foregroundColor(Theme.Colors.authority)
            
            // Card content
            ZStack {
                // Locked glass background (red gradient border)
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.authority.opacity(0.1),
                                Color(hex: "#110808").opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(Theme.Colors.authority.opacity(0.3), lineWidth: 1)
                    )
                
                // Glow effect
                Circle()
                    .fill(Theme.Colors.authority.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 40)
                    .offset(x: 30, y: -30)
                
                VStack(spacing: Theme.Spacing.xs) {
                    // Header with lock icon
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.Colors.authority)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.authority)
                            .frame(width: 56, height: 4)
                            .shadow(color: Theme.Colors.authority.opacity(0.5), radius: 6)
                        
                        Spacer()
                    }
                    
                    // Locked items (solid) — all 3 items
                    VStack(spacing: Theme.Spacing.xxs) {
                        lockedItem(width: 40)
                        lockedItem(width: 52)
                        lockedItem(width: 32)
                    }
                    
                    Spacer(minLength: 4)
                    
                    // No backdoors footer
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Theme.Colors.authority.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("NO BACKDOORS")
                            .font(.system(size: 7, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.Colors.authority.opacity(0.8))
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }
    
    func lockedItem(width: CGFloat) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: width, height: 8)
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.authority)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.Colors.authority.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.Colors.authority.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Descriptive List
private extension CoreDifferentiationContentView {
    var descriptiveList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Hard Commitments
            descriptiveItem(
                icon: "gavel",
                title: "Hard Commitments",
                description: "Once you set your non-negotiables, the \"Edit\" button disappears until the period ends."
            )
            
            // Psychological Certainty
            descriptiveItem(
                icon: "checkmark.shield",
                title: "Psychological Certainty",
                description: "Decision fatigue is eliminated. You don't decide if you'll do it; you already did."
            )
        }
    }
    
    func descriptiveItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Theme.Colors.authority.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Theme.Colors.authority.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.Colors.authority)
            }
            .frame(width: 32, height: 32)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Preview
struct CoreDifferentiationContentView_Previews: PreviewProvider {
    static var previews: some View {
        CoreDifferentiationContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
