import SwiftUI

struct PlanRegulatorSheet: View {
    let suggestions: [PlanSuggestionUIModel]
    let draftCount: Int
    let hasDraft: Bool
    let onApply: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Preview Draft")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Text("\(draftCount) placements ready")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                if suggestions.isEmpty {
                    Text("No recommendations available for this week.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                } else {
                    List {
                        ForEach(suggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(suggestion.protocolTitle)
                                        .font(.system(size: 13, weight: .bold))
                                    Spacer()
                                    Text(suggestion.kindLabel)
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(kindColor(suggestion.kind))
                                }
                                Text("\(suggestion.dayLabel) \(suggestion.slotLabel) • \(suggestion.confidenceLabel)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(suggestion.reason)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .listStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button("Discard") {
                        Haptics.selection()
                        onDiscard()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(accent.opacity(colorScheme == .dark ? 0.9 : 0.8))

                    Button("Apply Draft") {
                        Haptics.selection()
                        onApply()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .disabled(hasDraft == false)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .navigationTitle("Regulator")
            .navigationBarTitleDisplayMode(.inline)
            .tint(accent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.selection()
                        dismiss()
                    }
                }
            }
        }
    }

    func kindColor(_ kind: PlanSuggestionKind) -> Color {
        switch kind {
        case .recommendOnly: return Color(hex: "#2563EB")
        case .draftCandidate: return Color(hex: "#0891B2")
        case .warning: return .orange
        }
    }
}
