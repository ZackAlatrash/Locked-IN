#if DEBUG
import SwiftUI

struct DevSeedScenarioRow: View {
    let scenario: DevSeedScenario
    let onApply: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(scenario.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textMain)
                Text(scenario.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textMuted)
            }

            Spacer()

            Button("Apply") {
                Haptics.selection()
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .tint(colorScheme == .dark ? Color(hex: "22D3EE") : Color(hex: "0EA5E9"))
            .font(.system(size: 12, weight: .bold))
        }
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "111827")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color(hex: "6B7280")
    }
}
#endif
