import SwiftUI

struct DailyCheckInFlowView: View {
    @StateObject private var viewModel: DailyCheckInViewModel
    let isPopup: Bool
    let onFinish: (DailyCheckInDismissOutcome) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    init(
        commitmentStore: CommitmentSystemStore,
        planStore: PlanStore,
        router: AppRouter,
        referenceDateProvider: @escaping () -> Date = { Date() },
        isPopup: Bool = false,
        onFinish: @escaping (DailyCheckInDismissOutcome) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: DailyCheckInViewModel(
                commitmentStore: commitmentStore,
                planStore: planStore,
                router: router,
                referenceDateProvider: referenceDateProvider
            )
        )
        self.isPopup = isPopup
        self.onFinish = onFinish
    }

    var body: some View {
        Group {
            if isPopup {
                popupPanel
            } else {
                ZStack {
                    background
                    popupPanel
                        .padding(16)
                }
            }
        }
        .overlay(alignment: .top) {
            toastOverlay
        }
        .accessibilityAddTraits(isPopup ? .isModal : [])
        .onAppear {
            viewModel.refresh()
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                didAppear = true
            }
        }
        .onChange(of: viewModel.toastMessage) { message in
            guard let message else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                viewModel.consumeToastMessage(message)
            }
        }
    }
}

private extension DailyCheckInFlowView {
    var popupPanel: some View {
        VStack(spacing: 18) {
            stepContent
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(panelBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [primaryTone.opacity(0.09), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 260
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(panelBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.56), radius: 28, x: 0, y: 12)
        .opacity(didAppear ? 1 : 0)
        .offset(y: didAppear ? 0 : 12)
    }

    @ViewBuilder
    var stepContent: some View {
        switch viewModel.step {
        case .overview:
            overviewStep
        case .resolve, .recommendation:
            resolveStep
        case .closeDay:
            closeDayStep
        }
    }

    var toastOverlay: some View {
        VStack(spacing: 8) {
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#111827"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.08))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.14), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let warning = viewModel.warningMessage {
                Text(warning)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#111827"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorScheme == .dark ? Color.red.opacity(0.22) : Color.orange.opacity(0.22))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(colorScheme == .dark ? Color.red.opacity(0.45) : Color.orange.opacity(0.35), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 6)
    }

    var overviewStep: some View {
        VStack(spacing: 16) {
            overviewHeader

            if viewModel.protocolItems.isEmpty {
                DailyCheckInCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No active protocols today.")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(textMain)
                        Text("You can close the day or defer this check-in.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textMuted)
                    }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(viewModel.protocolItems) { item in
                            DailyCheckInProtocolRow(
                                item: item,
                                onMarkDone: {
                                    Haptics.softImpact()
                                    viewModel.markDone(protocolId: item.protocolId)
                                },
                                isRecoveryThemeActive: isRecoveryThemeActive
                            )
                        }
                    }
                }
                .frame(maxHeight: 360)
            }

            footerActions
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    var overviewHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    Haptics.selection()
                    onFinish(viewModel.dismissOutcome(completed: false))
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textMain)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close check-in")
            }

            statusPill

            Text(ritualStatusTitle)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .tracking(0.3)
                .foregroundColor(textMain)
                .textCase(.uppercase)

            Text(ritualStatusSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(primaryTone)
                .frame(width: 8, height: 8)
            Text("SYSTEM STATUS: \(ritualStatusHeadline)")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.1)
                .foregroundColor(primaryTone)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(primaryTone.opacity(0.1))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(primaryTone.opacity(0.22), lineWidth: 1)
        )
    }

    var footerActions: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.selection()
                handlePrimaryOverviewAction()
            } label: {
                Text(viewModel.unresolvedCount == 0 ? "COMMIT LOG" : "RESOLVE PROTOCOLS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(.plain)
            .foregroundColor(colorScheme == .dark ? Color(hex: "#00363A") : .white)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.unresolvedCount == 0 ? primaryTone : primaryTone.opacity(0.85))
            )
        }
    }

    func handlePrimaryOverviewAction() {
        if viewModel.unresolvedCount == 0 {
            viewModel.closeDay()
            return
        }

        if let unresolved = viewModel.protocolItems.first(where: { $0.needsAttention }) {
            viewModel.openResolve(protocolId: unresolved.protocolId)
            return
        }

        onFinish(viewModel.dismissOutcome(completed: false))
    }

    var resolveStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RESOLUTION")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(primaryTone)
                Spacer()
                Button {
                    Haptics.selection()
                    onFinish(viewModel.dismissOutcome(completed: false))
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(textMain)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close check-in")
            }

            if let protocolItem = viewModel.resolvingProtocol ?? viewModel.recommendationProtocol {
                DailyCheckInResolutionSheet(
                    protocolItem: protocolItem,
                    recommendation: viewModel.recommendation,
                    onRescheduleInPlan: {
                        Haptics.selection()
                        viewModel.resolveManually()
                        onFinish(viewModel.dismissOutcome(completed: false))
                    },
                    onRegulator: {
                        Haptics.selection()
                        viewModel.runSingleProtocolRegulator(protocolId: protocolItem.protocolId)
                    },
                    onApplyRecommendation: {
                        if viewModel.applyRecommendation() {
                            Haptics.success()
                        } else {
                            Haptics.warning()
                        }
                    },
                    onChooseManual: {
                        Haptics.selection()
                        viewModel.resolveManually()
                        onFinish(viewModel.dismissOutcome(completed: false))
                    },
                    onDismissRecommendation: {
                        Haptics.selection()
                        viewModel.dismissRecommendation()
                    }
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    var closeDayStep: some View {
        DailyCheckInCloseDayView(
            completedCount: viewModel.overview?.completedCount ?? 0,
            streakDays: viewModel.overview?.streakDays ?? 0,
            line: viewModel.closingLine(),
            onClose: {
                Haptics.success()
                onFinish(viewModel.dismissOutcome(completed: true))
            }
        )
        .transition(.opacity.combined(with: .scale))
    }

    var background: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(hex: "#081327"), Color(hex: "#020617")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(hex: "#F4F7FB")
            }
        }
        .ignoresSafeArea()
    }

    var panelBackground: Color {
        colorScheme == .dark ? Color(hex: "#201F22").opacity(0.82) : Color.white.opacity(0.94)
    }

    var panelBorder: Color {
        colorScheme == .dark ? Color(hex: "#849495").opacity(0.24) : Color.black.opacity(0.1)
    }

    var primaryTone: Color {
        if isRecoveryThemeActive {
            return colorScheme == .dark ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
        }
        return Color(hex: "#00F0FF")
    }

    var isRecoveryThemeActive: Bool {
        viewModel.overview?.modeLabel == "RECOVERY"
    }

    var textMain: Color {
        colorScheme == .dark ? Color(hex: "#E5E1E5") : Color(hex: "#0F172A")
    }

    var textMuted: Color {
        colorScheme == .dark ? Color(hex: "#B9CACB") : Color(hex: "#6B7280")
    }

    var ritualStatusHeadline: String {
        if viewModel.overview?.modeLabel == "RECOVERY" {
            return "RECOVERY"
        }
        return viewModel.unresolvedCount == 0 ? "STABLE" : "WATCH"
    }

    var ritualStatusTitle: String {
        viewModel.unresolvedCount == 0 ? "STABLE" : "PENDING"
    }

    var ritualStatusSubtitle: String {
        if viewModel.unresolvedCount == 0 {
            let streak = viewModel.overview?.streakDays ?? 0
            return "\(streak) clean days since last protocol breach"
        }
        let pending = viewModel.unresolvedCount
        let suffix = pending == 1 ? "protocol requires action" : "protocols require action"
        return "\(pending) \(suffix)"
    }
}
