//
//  UserHistoryContentView.swift
//  LockedIn
//
//  Content-only view for Screen 3 (User History)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Design sourced from Google Stitch MCP — EXACT MATCH
//

import SwiftUI

struct UserHistoryContentView: View {
    @EnvironmentObject var shellVM: OnboardingShellViewModel
    
    enum UserHistoryOption: String, CaseIterable, Identifiable {
        case stoppedUsing = "Yes, and I stopped using them"
        case didntWork = "Yes, they didn't work for me"
        case firstTime = "No, this is my first time"
        
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
                // Space for header overlay — push content toward center
                Spacer().frame(height: 180)
                
                // Content
                VStack(spacing: Theme.Spacing.xxl) {
                    // Question text
                    questionSection
                    
                    // Interactive selection cards
                    selectionCards
                    
                    // Stoic insight
                    stoicInsight
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
private extension UserHistoryContentView {
    var backgroundDecorations: some View {
        ZStack {
            // Top left glow
            Circle()
                .fill(Theme.Colors.authority.opacity(0.1))
                .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.4)
                .blur(radius: 120)
                .offset(x: -UIScreen.main.bounds.width * 0.2, y: -UIScreen.main.bounds.height * 0.1)
            
            // Bottom right glow
            Circle()
                .fill(Theme.Colors.authority.opacity(0.05))
                .frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.width * 0.3)
                .blur(radius: 100)
                .offset(x: UIScreen.main.bounds.width * 0.3, y: UIScreen.main.bounds.height * 0.35)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Question Section
private extension UserHistoryContentView {
    var questionSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            (
                Text("Have you tried ")
                    .foregroundColor(Theme.Colors.textPrimary)
                +
                Text("habit trackers")
                    .foregroundColor(Theme.Colors.authority)
                +
                Text(" before?")
                    .foregroundColor(Theme.Colors.textPrimary)
            )
            .font(.system(size: 30, weight: .heavy))
            .tracking(-0.5)
            .lineSpacing(2)
            .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Selection Cards
private extension UserHistoryContentView {
    var selectionCards: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(UserHistoryOption.allCases) { option in
                selectionCard(for: option)
            }
        }
    }
    
    func selectionCard(for option: UserHistoryOption) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                shellVM.selectedUserHistoryOption = option.rawValue
                shellVM.showValidationError = false
            }
        }) {
            HStack {
                Text(option.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(shellVM.selectedUserHistoryOption == option.rawValue ? Theme.Colors.textPrimary : Theme.Colors.textSecondary.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Radio button circle
                ZStack {
                    Circle()
                        .strokeBorder(
                            shellVM.selectedUserHistoryOption == option.rawValue ? Theme.Colors.authority : Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if shellVM.selectedUserHistoryOption == option.rawValue {
                        Circle()
                            .fill(Theme.Colors.authority)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        shellVM.selectedUserHistoryOption == option.rawValue
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.Colors.authority.opacity(0.15),
                                    Theme.Colors.authority.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.01)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(
                                shellVM.selectedUserHistoryOption == option.rawValue
                                    ? Theme.Colors.authority.opacity(0.5)
                                    : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: shellVM.selectedUserHistoryOption == option.rawValue
                            ? Theme.Colors.authority.opacity(0.2)
                            : Color.clear,
                        radius: shellVM.selectedUserHistoryOption == option.rawValue ? 20 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stoic Insight
private extension UserHistoryContentView {
    var stoicInsight: some View {
        Text("Most people don't fail from lack of effort — they fail from lack of constraints.")
            .font(.system(size: 14, weight: .light))
            .italic()
            .foregroundColor(Theme.Colors.textMuted)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.sm)
    }
}

// MARK: - Preview
struct UserHistoryContentView_Previews: PreviewProvider {
    static var previews: some View {
        UserHistoryContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
