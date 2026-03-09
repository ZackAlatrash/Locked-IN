import SwiftUI

extension PlanScreen {
    var textMain: Color { isDarkMode ? .white : Color(hex: "0B1220") }
    var textMuted: Color { isDarkMode ? Color.white.opacity(0.52) : Color(hex: "6B7280") }
    var textSubtle: Color { isDarkMode ? Color.white.opacity(0.34) : Color(hex: "9CA3AF") }
    var todayAccent: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171") : Color(hex: "B91C1C")
        }
        return isDarkMode ? Color(hex: "00F2FF") : Color(hex: "0F172A")
    }

    var structureColor: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171") : Color(hex: "B91C1C")
        }
        switch viewModel.structureStatus {
        case .structural: return isDarkMode ? Color(hex: "00F2FF") : Color(hex: "0EA5E9")
        case .fragile: return Color(hex: "F59E0B")
        case .unstructured: return Color(hex: "EF4444")
        }
    }

    var columnBackground: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "1A0C10").opacity(0.5) : Color.white.opacity(0.72)
        }
        return isDarkMode ? Color(hex: "0F172A").opacity(0.35) : Color.white.opacity(0.52)
    }

    var columnStroke: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171").opacity(0.22) : Color(hex: "FCA5A5").opacity(0.6)
        }
        return isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    var todayColumnBackground: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "2A1116").opacity(0.66) : Color.white.opacity(0.94)
        }
        return isDarkMode ? Color(hex: "001A2A").opacity(0.56) : Color.white.opacity(0.9)
    }

    var availableBackground: Color {
        return isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.015)
    }

    func glassCard(cornerRadius: CGFloat) -> some View {
        let fillColor: Color
        let strokeColor: Color
        if isRecoveryThemeActive {
            fillColor = isDarkMode ? Color(hex: "1B0A0D").opacity(0.55) : Color.white.opacity(0.86)
            strokeColor = isDarkMode ? Color(hex: "F87171").opacity(0.28) : Color(hex: "FCA5A5").opacity(0.62)
        } else {
            fillColor = isDarkMode ? Color(hex: "0F172A").opacity(0.4) : Color.white.opacity(0.8)
            strokeColor = isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
        }
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                fillColor
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        strokeColor,
                        lineWidth: 1
                    )
            )
    }

    func toneColor(for tone: PlanTone) -> Color {
        if isRecoveryThemeActive {
            switch tone {
            case .cyan: return isDarkMode ? Color(hex: "F87171") : Color(hex: "DC2626")
            case .indigo: return isDarkMode ? Color(hex: "FB7185") : Color(hex: "BE123C")
            case .purple: return isDarkMode ? Color(hex: "FDA4AF") : Color(hex: "B91C1C")
            case .amber: return isDarkMode ? Color(hex: "FCA5A5") : Color(hex: "991B1B")
            case .blue: return isDarkMode ? Color(hex: "EF4444") : Color(hex: "B91C1C")
            }
        }
        switch (tone, isDarkMode) {
        case (.cyan, true): return Color(hex: "00F2FF")
        case (.cyan, false): return Color(hex: "0EA5E9")
        case (.indigo, true): return Color(hex: "6366F1")
        case (.indigo, false): return Color(hex: "4F46E5")
        case (.purple, true): return Color(hex: "A855F7")
        case (.purple, false): return Color(hex: "7C3AED")
        case (.amber, true): return Color(hex: "F59E0B")
        case (.amber, false): return Color(hex: "D97706")
        case (.blue, true): return Color(hex: "38BDF8")
        case (.blue, false): return Color(hex: "0284C7")
        }
    }

    func allocationBackground(tone: PlanTone) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(toneColor(for: tone).opacity(isDarkMode ? 0.16 : 0.14))
            .shadow(
                color: toneColor(for: tone).opacity(isDarkMode ? 0.28 : 0.18),
                radius: isDarkMode ? 10 : 6,
                x: 0,
                y: 0
            )
    }

    var allocationTextColor: Color {
        isDarkMode ? .white : Color(hex: "0F172A")
    }

    @ViewBuilder
    var pageBackground: some View {
        if isDarkMode {
            if isRecoveryThemeActive {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "15080A"), Color(hex: "020203")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [Color(hex: "DC2626").opacity(0.34), .clear],
                        center: UnitPoint(x: 0.5, y: -0.08),
                        startRadius: 0,
                        endRadius: 440
                    )
                    RadialGradient(
                        colors: [Color(hex: "7F1D1D").opacity(0.28), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 380
                    )
                }
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "1A243D"), Color(hex: "020617")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        } else {
            ZStack {
                if isRecoveryThemeActive {
                    Color(hex: "FCF4F4")
                    RadialGradient(
                        colors: [Color(hex: "FCA5A5").opacity(0.44), .clear],
                        center: UnitPoint(x: 0.5, y: -0.08),
                        startRadius: 0,
                        endRadius: 420
                    )
                    RadialGradient(
                        colors: [Color(hex: "FECACA").opacity(0.42), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 420
                    )
                    RadialGradient(
                        colors: [Color(hex: "FCA5A5").opacity(0.3), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 440
                    )
                } else {
                    Color(hex: "F8F9FB")

                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 245.0 / 255.0, blue: 210.0 / 255.0).opacity(0.6),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: -0.1),
                        startRadius: 0,
                        endRadius: 380
                    )

                    RadialGradient(
                        colors: [
                            Color(red: 220.0 / 255.0, green: 225.0 / 255.0, blue: 1.0).opacity(0.5),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 450
                    )

                    RadialGradient(
                        colors: [
                            Color(red: 230.0 / 255.0, green: 220.0 / 255.0, blue: 1.0).opacity(0.5),
                            .clear
                        ],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 450
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}
