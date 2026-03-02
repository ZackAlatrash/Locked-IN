//
//  PrimaryButton.swift
//  LockedIn
//
//  Reusable full-width primary CTA button with arrow icon
//  Design sourced from Google Stitch MCP
//
//  Stitch CSS:
//    bg-primary hover:bg-primary/90 text-white rounded-lg h-16 px-8
//    justify-between (title left, arrow right)
//    text-lg font-bold tracking-wide uppercase
//    shadow-[0_8px_25px_rgba(234,42,51,0.3)]
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let showArrow: Bool
    let action: () -> Void
    
    init(
        title: String,
        showArrow: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.showArrow = showArrow
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Title on left (uppercase, bold, tracking-wide)
                Text(title.uppercased())
                    .font(Theme.Typography.buttonLarge())
                    .tracking(Theme.Typography.letterSpacingWide * 18) // tracking-wide relative to font size
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .layoutPriority(1)
                
                Spacer(minLength: 16)
                
                // Arrow on right
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 64) // h-16 = 64px
            .padding(.horizontal, Theme.Spacing.xxl) // px-8 = 32px
            .background(Theme.Colors.authority)
            .cornerRadius(Theme.CornerRadius.sm) // rounded-lg = 8px
            .shadow(
                color: Theme.Colors.authority.opacity(0.3),
                radius: 25,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Button Style
private struct PrimaryButtonStyle: ButtonStyle {
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
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.lg) {
            PrimaryButton(title: "I Understand", showArrow: true) {}
            PrimaryButton(title: "Get Started", showArrow: false) {}
        }
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.backgroundPrimary)
        .previewLayout(.sizeThatFits)
    }
}
