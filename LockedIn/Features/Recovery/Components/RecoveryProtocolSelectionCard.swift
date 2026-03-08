import SwiftUI

struct RecoveryProtocolSelectionCard: View {
    let option: RecoveryProtocolOption
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#111827")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color(hex: "#6B7280")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    Text(option.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textMain)
                        .lineLimit(1)

                    if option.isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(accent.opacity(colorScheme == .dark ? 0.18 : 0.12)))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? accent : textMuted)
                }

                HStack(spacing: 8) {
                    chip(option.modeLabel)
                    chip(option.weeklyLoadText)
                    chip("\(option.currentWindowViolations) violations")
                    chip("\(option.plannedLoadCount) planned")
                }

                Text(option.stateText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                            ? accent.opacity(0.82)
                            : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    func chip(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(textMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05))
            )
    }
}
