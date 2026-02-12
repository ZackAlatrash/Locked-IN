//
//  AIRegulatorContentView.swift
//  LockedIn
//
//  Content-only view for Screen 7 (AI Regulator)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Design sourced from Google Stitch MCP — EXACT MATCH
//

import SwiftUI

struct AIRegulatorContentView: View {
    @State private var showPulse = false
    
    var body: some View {
        ZStack {
            // Full-screen background
            Theme.Colors.backgroundPrimary
            
            // Main content
            VStack(spacing: 0) {
                // Space for header overlay
                Spacer().frame(height: 160)
                
                // Content - compact to fit on one screen
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Sentinel AI Icon
                        sentinelIcon
                        
                        // Headline
                        headlineSection
                        
                        // Cockpit Panel / Simulation
                        simulationPanel
                        
                        // System Message
                        systemMessage
                        
                        // Scroll hint
                        scrollHint
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
                }
                
                // Space for CTA button
                Spacer().frame(height: 140)
            }
        }
    }
}

// MARK: - Sentinel AI Icon
private extension AIRegulatorContentView {
    var sentinelIcon: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Theme.Colors.authority.opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
            
            // Icon container
            ZStack {
                Circle()
                    .fill(Theme.Colors.backgroundPrimary)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.authority.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Theme.Colors.authority)
            }
            .frame(width: 64, height: 64)
            
            // Pulsing ring
            Circle()
                .stroke(Theme.Colors.authority.opacity(0.2), lineWidth: 1)
                .frame(width: 64, height: 64)
                .scaleEffect(showPulse ? 1.3 : 1.0)
                .opacity(showPulse ? 0 : 0.5)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: showPulse
                )
                .onAppear {
                    showPulse = true
                }
        }
    }
}

// MARK: - Headline Section
private extension AIRegulatorContentView {
    var headlineSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("The AI enforces realism.")
                .font(.system(size: 24, weight: .heavy))
                .tracking(-0.5)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("It does not motivate you. It prevents overcommitment and forces recovery when needed.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
}

// MARK: - Simulation Panel
private extension AIRegulatorContentView {
    var simulationPanel: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.authority.opacity(0.1),
                            Theme.Colors.backgroundPrimary.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            
            // Scanline effect
            scanlineOverlay
            
            VStack(spacing: Theme.Spacing.md) {
                // Header row
                HStack {
                    Text("System ID: REG_07X")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(-0.5)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text("Live Simulation")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(-0.5)
                        .foregroundColor(Theme.Colors.authority)
                }
                
                // Attempted Action Card with Denial Overlay
                ZStack {
                    // Non-negotiable card (attempted action)
                    NonNegotiableCard(
                        title: "Learn Spanish",
                        frequency: "daily",
                        lockDurationDays: 28,
                        startDate: Date()
                    )
                    .opacity(0.4)
                    
                    // Denial stamp
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.system(size: 12))
                        
                        Text("Denied: Capacity Exceeded")
                            .font(.system(size: 11, weight: .black))
                            .tracking(-0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.authority)
                    .cornerRadius(Theme.CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .rotationEffect(.degrees(-2))
                }
                
                // Vertical divider
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.Colors.authority.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: 24)
                    Spacer()
                }
                
                // Adjusted Plan
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.authority)
                        
                        Text("Adjusted Plan")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    VStack(spacing: Theme.Spacing.xs) {
                        // 08:00 - Deep Work
                        scheduleRow(time: "08:00", label: "Deep Work", isActive: false)
                        
                        // 10:00 - Forced Recovery (highlighted)
                        scheduleRow(time: "10:00", label: "Forced Recovery", isActive: true, isMandatory: true)
                        
                        // 11:00 - Gym Session
                        scheduleRow(time: "11:00", label: "Gym Session", isActive: false)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    func scheduleRow(time: String, label: String, isActive: Bool, isMandatory: Bool = false) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(time)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(isActive ? Theme.Colors.authority : Theme.Colors.textTertiary)
                .frame(width: 36, alignment: .leading)
            
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? Theme.Colors.authority : Theme.Colors.textSecondary)
                
                Spacer()
                
                if isMandatory {
                    Text("Mandatory")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.authority.opacity(0.6))
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .fill(isActive ? Theme.Colors.authority.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .stroke(isActive ? Theme.Colors.authority : Color.white.opacity(0.2), lineWidth: isActive ? 2 : 1)
                    .frame(width: 2)
                    .offset(x: -1),
                alignment: .leading
            )
        }
        .opacity(isActive ? 1.0 : 0.6)
    }
    
    var scanlineOverlay: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<Int(geometry.size.height / 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Theme.Colors.authority.opacity(0.03))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - System Message
private extension AIRegulatorContentView {
    var systemMessage: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textTertiary)
            
            Text("**REG_LOG:** Analysis shows 94% failure rate for adding \"Spanish\" to current cognitive load. Schedule recalibrated to prioritize CNS recovery.")
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.textTertiary)
                .lineSpacing(2)
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    var scrollHint: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textTertiary.opacity(0.6))
            
            Text("Scroll for more")
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(Theme.Colors.textTertiary.opacity(0.5))
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Preview
struct AIRegulatorContentView_Previews: PreviewProvider {
    static var previews: some View {
        AIRegulatorContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
