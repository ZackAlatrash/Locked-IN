//
//  CreateNonNegotiableContentView.swift
//  LockedIn
//
//  Content-only view for Screen 6 (Create Non-Negotiable)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Design sourced from Google Stitch MCP — EXACT MATCH
//

import SwiftUI

struct CreateNonNegotiableContentView: View {
    // MARK: - Bindings (explicit dependency injection)
    @Binding var action: String
    @Binding var frequency: String
    @Binding var minimum: String
    @Binding var showValidationError: Bool
    
    enum Frequency: String, CaseIterable, Identifiable {
        case daily = "Every Day"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case custom = "Custom Schedule"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            // Full-screen background
            Theme.Colors.backgroundPrimary
            
            // Background decorative elements
            backgroundDecorations
            
            // Main content
            VStack(spacing: 0) {
                // Space for header overlay
                Spacer().frame(height: 180)
                
                // Content
                VStack(spacing: Theme.Spacing.xl) {
                    // Header text
                    headerSection
                    
                    // Input fields
                    inputFields
                    
                    // Footer note
                    footerNote
                }
                .padding(.horizontal, Theme.Spacing.xl)
                
                Spacer()
                
                // Space for CTA button
                Spacer().frame(height: 160)
            }
        }
    }
}

// MARK: - Background Decorations
private extension CreateNonNegotiableContentView {
    var backgroundDecorations: some View {
        ZStack {
            // Top left glow
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: 280, height: 280)
                .blur(radius: 120)
                .offset(x: -UIScreen.main.bounds.width * 0.2, y: -UIScreen.main.bounds.height * 0.15)
            
            // Bottom right glow
            Circle()
                .fill(Theme.Colors.authority.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 100)
                .offset(x: UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.25)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Header Section
private extension CreateNonNegotiableContentView {
    var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Headline
            Text("Create one non-negotiable\nto try the system.")
                .font(.system(size: 26, weight: .heavy))
                .tracking(-0.5)
                .lineSpacing(2)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Action precedes motivation. Choose your first task.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Input Fields
private extension CreateNonNegotiableContentView {
    var inputFields: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Action Field
            inputCard(
                label: "ACTION",
                icon: "bolt.fill",
                content: {
                    TextField("", text: $action, prompt: Text("e.g. Cold Shower").foregroundColor(Theme.Colors.textTertiary.opacity(0.5)))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .onChange(of: action) { _ in
                            showValidationError = false
                        }
                }
            )
            
            // Frequency Field
            inputCard(
                label: "FREQUENCY",
                icon: "calendar",
                content: {
                    Menu {
                        ForEach(Frequency.allCases) { freq in
                            Button(action: {
                                frequency = freq.rawValue
                            }) {
                                Text(freq.rawValue)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                    } label: {
                        HStack {
                            Text(frequency)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            )
            
            // Minimum Requirement Field
            inputCard(
                label: "MINIMUM REQUIREMENT",
                icon: "speedometer",
                content: {
                    TextField("", text: $minimum, prompt: Text("e.g. 5 Minutes").foregroundColor(Theme.Colors.textTertiary.opacity(0.5)))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .onChange(of: minimum) { _ in
                            showValidationError = false
                        }
                }
            )
        }
    }
    
    func inputCard<Content: View>(label: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Label row with icon
                HStack {
                    Text(label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(Theme.Typography.letterSpacingWidest * 7.5)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.authority)
                }
                
                // Input content
                content()
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

// MARK: - Footer Note
private extension CreateNonNegotiableContentView {
    var footerNote: some View {
        Text("This is a trial commitment for onboarding.\nYou can adjust these parameters later.")
            .font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .foregroundColor(Theme.Colors.textMuted)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

// MARK: - Preview
struct CreateNonNegotiableContentView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNonNegotiableContentView(
            action: .constant(""),
            frequency: .constant("Every Day"),
            minimum: .constant(""),
            showValidationError: .constant(false)
        )
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
