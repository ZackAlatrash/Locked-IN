import SwiftUI

struct DailyCheckInFlowView: View {
    @StateObject private var viewModel: DailyCheckInViewModel
    let isPopup: Bool
    let onFinish: (DailyCheckInDismissOutcome) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    init(
        commitmentStore: RepositoryCommitmentService,
        planStore: RepositoryPlanService,
        router: AppRouter,
        referenceDateProvider: @escaping () -> Date = { Date() },
        isPopup: Bool = false,
        onFinish: @escaping (DailyCheckInDismissOutcome) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: DailyCheckInViewModel(
                commitmentStore: commitmentStore,
                planStore: planStore,
                commitmentService: commitmentStore,
                planService: planStore,
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
                content
            } else {
                ZStack {
                    background
                    content
                }
            }
        }
        .overlay(alignment: .top) {
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
                    .padding(.top, 6)
            }
        }
        .toast(message: Binding(
            get: { viewModel.toastMessage },
            set: { newValue in
                if newValue == nil, let current = viewModel.toastMessage {
                    viewModel.consumeToastMessage(current)
                }
            }
        ), style: colorScheme == .dark ? .dark : .light)
        .onAppear {
            viewModel.refresh()
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                didAppear = true
            }
        }
    }
}

private extension DailyCheckInFlowView {
    var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header
                if let overview = viewModel.overview, viewModel.step != .closeDay {
                    overviewCard(overview)
                }
                contentForStep
            }
            .padding(.horizontal, isPopup ? 14 : 16)
            .padding(.top, isPopup ? 12 : 14)
            .padding(.bottom, isPopup ? 18 : 24)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 12)
        }
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

    var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#0F172A")
    }

    var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color(hex: "#6B7280")
    }

    var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("DAILY CHECK-IN")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.6)
                    .foregroundColor(accent)
                Text("Close today with intent.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textMuted)
            }
            Spacer()
            if viewModel.step != .closeDay {
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
        }
    }

    func overviewCard(_ overview: DailyCheckInOverviewModel) -> some View {
        DailyCheckInCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(overview.dateLabel)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(textMain)
                        Text("\(overview.completedCount) done • \(overview.needsAttentionCount) needs attention")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Text(overview.modeLabel)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(accent.opacity(colorScheme == .dark ? 0.16 : 0.12))
                        )
                }

                HStack(spacing: 10) {
                    overviewMetric(title: "Reliability", value: "\(overview.reliabilityScore)%")
                    overviewMetric(title: "Streak", value: "\(overview.streakDays)d")
                }
            }
        }
    }

    func overviewMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(textMuted)
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var contentForStep: some View {
        switch viewModel.step {
        case .overview:
            overviewStep
        case .resolve:
            resolveStep
        case .recommendation:
            resolveStep
        case .closeDay:
            closeDayStep
        }
    }

    var overviewStep: some View {
        Group {
            if viewModel.protocolItems.isEmpty {
                DailyCheckInCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No active protocols today.")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(textMain)
                        Text("Close the day and continue tomorrow.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textMuted)
                        Button("Close Day") {
                            Haptics.selection()
                            viewModel.closeDay()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    }
                }
            } else {
                DailyCheckInCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today Protocols")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(textMain)
                        ForEach(viewModel.protocolItems) { item in
                            DailyCheckInProtocolRow(
                                item: item,
                                onMarkDone: {
                                    Haptics.softImpact()
                                    viewModel.markDone(protocolId: item.protocolId)
                                },
                                onResolve: {
                                    Haptics.selection()
                                    viewModel.openResolve(protocolId: item.protocolId)
                                }
                            )
                        }
                    }
                }

                if viewModel.unresolvedCount == 0 {
                    Button("Close Day") {
                        Haptics.selection()
                        viewModel.closeDay()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Button("Close for now") {
                        Haptics.selection()
                        onFinish(viewModel.dismissOutcome(completed: false))
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    var resolveStep: some View {
        Group {
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
}
