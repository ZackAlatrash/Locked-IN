//
//  NonNegotiableCard.swift
//  LockedIn
//
//  Reusable Non-Negotiable card component
//  Used in onboarding and throughout the app
//  Design: Liquid glass with lock icon and countdown timer
//

import SwiftUI
import Combine

struct NonNegotiableCard: View {
    let title: String
    let frequency: String
    let lockDurationDays: Int
    let startDate: Date
    let accentColor: Color
    let useSolidStyle: Bool
    
    @State private var timeRemaining: TimeInterval
    @State private var timerSubscription: AnyCancellable?
    
    init(
        title: String,
        frequency: String,
        lockDurationDays: Int,
        startDate: Date,
        accentColor: Color = Theme.Colors.authority,
        useSolidStyle: Bool = false
    ) {
        self.title = title
        self.frequency = frequency
        self.lockDurationDays = lockDurationDays
        self.startDate = startDate
        self.accentColor = accentColor
        self.useSolidStyle = useSolidStyle
        let endDate = Calendar.current.date(byAdding: .day, value: lockDurationDays, to: startDate) ?? Date()
        _timeRemaining = State(initialValue: endDate.timeIntervalSince(Date()))
    }
    
    var body: some View {
        Group {
            if useSolidStyle {
                cardContent
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(Color(hex: "#1b2737"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            } else {
                GlassCard {
                    cardContent
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Logic
    
    private func startTimer() {
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateTimeRemaining()
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func updateTimeRemaining() {
        let endDate = Calendar.current.date(byAdding: .day, value: lockDurationDays, to: startDate) ?? Date()
        timeRemaining = endDate.timeIntervalSince(Date())
        if timeRemaining < 0 {
            timeRemaining = 0
        }
    }
    
    private var formattedTimeRemaining: String {
        let days = Int(timeRemaining) / 86400
        let hours = (Int(timeRemaining) % 86400) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
    
    // MARK: - Divider
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Top Section with Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    // Non-Negotiable label
                    Text("NON-NEGOTIABLE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(Theme.Typography.letterSpacingWidest * 10)
                        .foregroundColor(accentColor)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 28, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    // Frequency subtitle
                    Text(frequency)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Lock icon container
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(accentColor.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .frame(width: 48, height: 48)
            }
            .padding(.bottom, Theme.Spacing.md)
            
            // Visual Divider
            dividerLine
                .padding(.bottom, Theme.Spacing.md)
            
            // Bottom Section with Countdown
            HStack {
                // Commitment info
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMMITMENT")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("Locked \(lockDurationDays) days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Countdown timer
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                        .foregroundColor(accentColor)
                    
                    Text(formattedTimeRemaining)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(-0.5)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(Theme.Spacing.lg)
    }
    
    private var dividerLine: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 1)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: 1)
        }
    }
}

// MARK: - Preview
struct NonNegotiableCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
            
            NonNegotiableCard(
                title: "Gym",
                frequency: "3× per week",
                lockDurationDays: 28,
                startDate: Date()
            )
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}
