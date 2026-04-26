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
    var backgroundColor: Color = Theme.Colors.authority
    var foregroundColor: Color = Theme.Colors.textPrimary
    let action: () -> Void

    init(
        title: String,
        showArrow: Bool = true,
        backgroundColor: Color = Theme.Colors.authority,
        foregroundColor: Color = Theme.Colors.textPrimary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.showArrow = showArrow
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title.uppercased())
                    .font(Theme.Typography.buttonLarge())
                    .tracking(Theme.Typography.letterSpacingWide * 18)
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: title)

                Spacer(minLength: 16)

                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(foregroundColor)
                        .frame(width: 24)
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 64)
            .background(backgroundColor)
            .cornerRadius(Theme.CornerRadius.lg) // 16px — matches main app card radius
            .shadow(
                color: backgroundColor.opacity(0.3),
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
