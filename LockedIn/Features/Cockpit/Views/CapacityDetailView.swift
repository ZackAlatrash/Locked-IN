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
    private var textSecondary: Color { isDarkMode ? Color.white.opacity(0.78) : Color(hex: "4B5563") }
    private var textMuted: Color { isDarkMode ? Color.white.opacity(0.62) : Color(hex: "6B7280") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerPanel

                VStack(alignment: .leading, spacing: 10) {
                    Text("Protocols")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(textSecondary)

                    if visibleProtocols.isEmpty {
                        Text("No active protocols")
                            .font(.body.weight(.medium))
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
                        .font(.headline.weight(.bold))
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
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textMuted)

            Text("\(system.activeNonNegotiables.count) / \(system.allowedCapacity)")
                .font(.title2.weight(.heavy))
                .foregroundColor(textMain)

            Text(system.nonNegotiables.contains(where: { $0.state == .recovery }) ? "Recovery constraints active" : "Normal constraints active")
                .font(.body.weight(.medium))
                .foregroundColor(textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
                        .font(.body.weight(.bold))
                        .foregroundColor(textMain)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(nn.definition.frequencyPerWeek)/week • \(stateText(nn.state))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()

                Text(stateBadge(nn.state))
                    .font(.caption2.weight(.bold))
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
            return accentColor.opacity(0.28)
        case .recovery:
            return Color.red.opacity(0.30)
        case .suspended:
            return Color.orange.opacity(0.30)
        default:
            return isDarkMode ? Color.white.opacity(0.20) : Color.black.opacity(0.08)
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
