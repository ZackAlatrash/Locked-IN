import SwiftUI

struct CapacityDetailView: View {
    let system: CommitmentSystem
    let accentColor: Color
    let onSelectProtocol: (UUID) -> Void
    let onOpenLogs: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    private var cardBackground: Color { isDarkMode ? Color(hex: "#1C1C1E") : Color.white }
    private var rowBackground: Color { isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }
    private var textMain: Color { isDarkMode ? Color.white : Color(hex: "101827") }
    private var textSecondary: Color { isDarkMode ? Color.white.opacity(0.72) : Color(hex: "6B7280") }
    private var textMuted: Color { isDarkMode ? Color.white.opacity(0.48) : Color(hex: "9CA3AF") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerPanel

                VStack(alignment: .leading, spacing: 10) {
                    Text("Protocols")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)

                    if visibleProtocols.isEmpty {
                        Text("No active protocols")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textMuted)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(rowBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ForEach(visibleProtocols, id: \.id) { nn in
                            protocolRow(nn)
                        }
                    }
                }

                Button {
                    onOpenLogs()
                } label: {
                    Text("Open Logs")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(accentColor)
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Capacity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CapacityDetailView {
    var visibleProtocols: [NonNegotiable] {
        system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery || $0.state == .suspended
        }
    }

    var headerPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Capacity")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMuted)

            Text("\(system.activeNonNegotiables.count) / \(system.allowedCapacity)")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(textMain)

            Text(system.nonNegotiables.contains(where: { $0.state == .recovery }) ? "Recovery constraints active" : "Normal constraints active")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textSecondary)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func protocolRow(_ nn: NonNegotiable) -> some View {
        Button {
            onSelectProtocol(nn.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nn.definition.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(textMain)
                    Text("\(nn.definition.frequencyPerWeek)/week • \(stateText(nn.state))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                }

                Spacer()

                Text(stateBadge(nn.state))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(badgeBackground(nn.state))
                    .foregroundColor(badgeColor(nn.state))
                    .clipShape(Capsule())
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func stateText(_ state: NonNegotiableState) -> String {
        switch state {
        case .active: return "Active"
        case .recovery: return "Recovery"
        case .suspended: return "Suspended"
        case .completed: return "Completed"
        case .retired: return "Retired"
        case .draft: return "Draft"
        }
    }

    func stateBadge(_ state: NonNegotiableState) -> String {
        switch state {
        case .active: return "ACTIVE"
        case .recovery: return "RECOVERY"
        case .suspended: return "SUSPENDED"
        case .completed: return "COMPLETED"
        case .retired: return "RETIRED"
        case .draft: return "DRAFT"
        }
    }

    func badgeBackground(_ state: NonNegotiableState) -> Color {
        switch state {
        case .active:
            return accentColor.opacity(0.18)
        case .recovery:
            return Color.red.opacity(0.18)
        case .suspended:
            return Color.orange.opacity(0.20)
        default:
            return Color.white.opacity(0.14)
        }
    }

    func badgeColor(_ state: NonNegotiableState) -> Color {
        switch state {
        case .active:
            return accentColor
        case .recovery:
            return Color.red.opacity(0.95)
        case .suspended:
            return Color.orange.opacity(0.95)
        default:
            return textMuted
        }
    }
}
