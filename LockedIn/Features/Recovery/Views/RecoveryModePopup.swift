import SwiftUI

struct RecoveryModePopup: View {
    @StateObject private var viewModel: RecoveryModeViewModel
    let onResolved: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    init(
        commitmentStore: CommitmentSystemStore,
        planStore: PlanStore,
        referenceDateProvider: @escaping () -> Date = { Date() },
        onResolved: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: RecoveryModeViewModel(
                commitmentStore: commitmentStore,
                planStore: planStore,
                referenceDateProvider: referenceDateProvider
            )
        )
        self.onResolved = onResolved
    }

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#111827")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "#6B7280")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            stepContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            if let warning = viewModel.warningMessage {
                Text(warning)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorScheme == .dark ? Color.red.opacity(0.22) : Color.orange.opacity(0.2))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(colorScheme == .dark ? Color.red.opacity(0.45) : Color.orange.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.top, -6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.refresh()
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                didAppear = true
            }
        }
        .onChange(of: viewModel.isPendingResolution) { _, isPending in
            if isPending == false {
                onResolved()
            }
        }
        .onChange(of: didAppear) { _, _ in
            viewModel.dismissWarning()
        }
        .opacity(didAppear ? 1 : 0)
        .offset(y: didAppear ? 0 : 10)
    }
}

private extension RecoveryModePopup {
    var header: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("RECOVERY MODE ENTERED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(accent)
                Text("Your system is overloaded. We need to reduce pressure.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textMain)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    var stepContent: some View {
        switch viewModel.step {
        case .entry:
            entryStep
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        case .selectProtocol:
            selectProtocolStep
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        case .confirmed:
            confirmedStep
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    var entryStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            DailyCheckInCard {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.requiresPauseSelection {
                        Text("Too many violations occurred inside the current 14-day window. To continue, pause one protocol while recovery stabilizes the system.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textMuted)
                        Text("You can resume automatically after 7 clean days.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(textMuted)
                    } else {
                        Text("Recovery has started. No pause is required because only one active protocol remains.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textMuted)
                        Text("Keep clean days to return to normal operation.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(textMuted)
                    }

                    if let trigger = viewModel.triggerProtocolTitle {
                        Text("Triggered by: \(trigger)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(textMain.opacity(0.82))
                            .padding(.top, 2)
                    }
                }
            }

            Button {
                Haptics.selection()
                withAnimation(reduceMotion ? .none : Theme.Animation.content) {
                    viewModel.continueFromEntry()
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
    }

    var selectProtocolStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose One Protocol To Pause")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(textMain)

            Text("Select exactly one active protocol. Paused protocols cannot be completed, planned, or regulator-placed during recovery.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textMuted)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 9) {
                    ForEach(viewModel.protocolOptions) { option in
                        RecoveryProtocolSelectionCard(
                            option: option,
                            isSelected: viewModel.selectedProtocolId == option.id,
                            onTap: {
                                Haptics.selection()
                                viewModel.selectProtocol(option.id)
                            }
                        )
                    }
                }
                .padding(.vertical, 1)
            }
            .frame(maxHeight: 300)

            Button {
                let success = viewModel.confirmPauseSelection()
                if success {
                    Haptics.success()
                } else {
                    Haptics.warning()
                }
            } label: {
                Text("Pause Selected Protocol")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .disabled(viewModel.canConfirmPauseSelection == false)
            .opacity(viewModel.canConfirmPauseSelection ? 1 : 0.55)
        }
    }

    var confirmedStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            DailyCheckInCard {
                VStack(alignment: .leading, spacing: 10) {
                    if let paused = viewModel.pausedProtocolTitle {
                        Text("\(paused) is now paused during recovery.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(textMain)
                    } else {
                        Text("Recovery started with no pause required.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(textMain)
                    }

                    Text("Recovery law: complete at least one counted protocol each day, and avoid new violations for 7 clean days.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textMuted)
                }
            }

            Button {
                Haptics.success()
                viewModel.completeFlow()
                onResolved()
            } label: {
                Text("Return to Cockpit")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
    }
}
