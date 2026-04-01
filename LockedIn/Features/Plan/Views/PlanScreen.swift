import SwiftUI
import UIKit
import Combine

private enum PlanBoardMode {
    case focusToday
    case expandedWeek
}

struct PlanScreen: View {
    @Binding var selectedTab: MainTab

    @EnvironmentObject private var commitmentStore: CommitmentSystemStore
    @EnvironmentObject private var planStore: PlanStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appClock: AppClock
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("phase1MotionSessionID") private var motionSessionID = ""
    @AppStorage("didAnimatePlanColumnsSessionID") private var didAnimatePlanColumnsSessionID = ""
    @AppStorage("didDismissPlanBoardHintSessionID") private var didDismissPlanBoardHintSessionID = ""
    @AppStorage("didDismissPlanCalendarConnectedBannerSessionID") private var didDismissPlanCalendarConnectedBannerSessionID = ""

    @StateObject private var viewModel = PlanViewModel()
    @State private var showProfile = false
    @State private var boardMode: PlanBoardMode = .focusToday
    @State private var activeDragPayload: String?
    @State private var targetedSlotId: String?
    @State private var toast: PlanToast?
    @State private var pendingUndo: PlanUndoAction?
    @State private var revealedDayIds: Set<Date> = []
    @State private var didRunColumnEntrance = false
    @State private var recentlyLockedAllocationKeys: Set<String> = []
    @State private var lockInPulseActive = false
    @ScaledMetric(relativeTo: .body) private var compactDayWidth: CGFloat = 80
    @ScaledMetric(relativeTo: .body) private var regularDayWidth: CGFloat = 194
    @ScaledMetric(relativeTo: .body) private var todayDayWidth: CGFloat = 198
    @ScaledMetric(relativeTo: .body) private var compactSlotHeight: CGFloat = 150
    @ScaledMetric(relativeTo: .body) private var expandedSlotHeight: CGFloat = 188
    @ScaledMetric(relativeTo: .body) private var queueCardBaseWidth: CGFloat = 228

    private var isDarkMode: Bool { colorScheme == .dark }
    private var isRecoveryThemeActive: Bool { commitmentStore.isSystemStable == false }
    private var navItemColor: Color { isDarkMode ? Theme.Colors.textSecondary : Color(hex: "111827") }
    private var accentColor: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
        }
        return isDarkMode ? Color(hex: "#00F2FF") : Color(hex: "#0EA5E9")
    }
    private var effectiveMotionSessionID: String { motionSessionID.isEmpty ? "launch-pending" : motionSessionID }
    private var didAnimateColumnsThisSession: Bool {
        didAnimatePlanColumnsSessionID == effectiveMotionSessionID
    }
    private var shouldShowBoardHint: Bool {
        boardMode == .focusToday && didDismissPlanBoardHintSessionID != effectiveMotionSessionID
    }
    private var shouldShowCalendarConnectionBanner: Bool {
        if viewModel.isCalendarConnected == false {
            return true
        }
        return didDismissPlanCalendarConnectedBannerSessionID != effectiveMotionSessionID
    }

    var body: some View {
        ZStack {
            pageBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if shouldShowQueueSection {
                        queueSection
                    } else {
                        allScheduledCue
                    }
                    planBoardSection
                    todayAtGlanceSection
                    distributionStatus
                    legend
                }
                .padding(.horizontal, 14)
                .padding(.top, Theme.Spacing.navLargeTitleContentTopInset)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ProfileToolbarButton(foregroundColor: navItemColor) {
                    Haptics.selection()
                    showProfile = true
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfilePlaceholderView()
            }
        }
        .sheet(item: $viewModel.selectedAllocation) { allocation in
            PlanAllocationEditorSheet(
                allocation: allocation,
                weekDays: viewModel.currentWeekDays,
                titleForProtocol: { id in viewModel.protocolTitle(for: id) },
                onMove: { day, slot in
                    viewModel.moveAllocation(allocationId: allocation.id, to: day, slot: slot)
                },
                onRemove: {
                    viewModel.removeAllocation(allocationId: allocation.id)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingRegulatorSheet) {
            PlanRegulatorSheet(
                suggestions: viewModel.regulatorSuggestions,
                draftCount: viewModel.draftAllocations.count,
                hasDraft: viewModel.hasDraft,
                onApply: {
                    let draftToApply = viewModel.draftAllocations
                    if viewModel.applyDraft() {
                        Haptics.success()
                        triggerRegulatorLockInAnimation(for: draftToApply)
                    } else {
                        Haptics.warning()
                    }
                },
                onDiscard: {
                    Haptics.selection()
                    viewModel.discardDraft()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.protocolSchedulingEditor) { editor in
            ProtocolSchedulingEditorSheet(
                editor: editor,
                errorMessage: viewModel.protocolEditErrorMessage,
                onSave: { title, preferredSlot, durationMinutes, iconSystemName, mode, frequencyPerWeek, lockDays in
                    viewModel.saveProtocolEditor(
                        id: editor.id,
                        title: title,
                        preferredSlot: preferredSlot,
                        durationMinutes: durationMinutes,
                        iconSystemName: iconSystemName,
                        mode: mode,
                        frequencyPerWeek: frequencyPerWeek,
                        lockDays: lockDays
                    )
                },
                onCancel: {
                    Haptics.selection()
                    viewModel.dismissProtocolEditor()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            boardMode = .focusToday
            viewModel.setReferenceDateProvider { appClock.now }
            viewModel.bind(planStore: planStore, commitmentStore: commitmentStore)
            viewModel.refresh(referenceDate: appClock.now)
            handleExternalPlanFocus(router.pendingPlanFocusProtocolId)
            handleExternalPlanEdit(router.pendingPlanEditProtocolId)
        }
        .onChange(of: router.pendingPlanFocusProtocolId) { protocolId in
            handleExternalPlanFocus(protocolId)
        }
        .onChange(of: router.pendingPlanEditProtocolId) { protocolId in
            handleExternalPlanEdit(protocolId)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.handleDidBecomeActive(referenceDate: appClock.now)
            }
        }
        .onChange(of: appClock.simulatedNow) { _ in
            viewModel.refresh(referenceDate: appClock.now)
        }
        .overlay(alignment: .top) {
            warningBanner
        }
        .overlay(alignment: .bottom) {
            if let toast {
                planToastView(toast)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 22)
            }
        }
    }
}

private extension PlanScreen {
    @ViewBuilder
    var warningBanner: some View {
        if let warning = viewModel.warningMessage {
            PlanWarningBannerView(
                title: viewModel.warningCopy?.title,
                message: viewModel.warningCopy?.message ?? warning,
                hint: viewModel.warningCopy?.hint,
                isDarkMode: isDarkMode
            )
        }
    }

    var shouldShowQueueSection: Bool {
        viewModel.queueItems.isEmpty == false || viewModel.hasTrackableProtocols == false
    }

    var allScheduledCue: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.callout.weight(.bold))
                .foregroundColor(toneColor(for: .cyan))

            Text("All protocols are scheduled.")
                .font(.footnote.weight(.semibold))
                .foregroundColor(textMain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(glassCard(cornerRadius: 14))
    }

    var planBoardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            planBoardHeader
            if shouldShowCalendarConnectionBanner {
                calendarConnectionBanner
            }
            if shouldShowBoardHint {
                boardScrollHint
            }
            weekPillars
        }
    }

    var planBoardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STRUCTURAL PLAN")
                    .font(.caption.weight(.bold))
                    .fontDesign(.monospaced)
                    .tracking(2)
                    .foregroundColor(isDarkMode ? Color(hex: "00D9FF") : Color(hex: "334155"))
                Text(viewModel.weekSubtitle)
                    .font(.caption.weight(.semibold))
                    .fontDesign(.monospaced)
                    .tracking(1.2)
                    .foregroundColor(textMuted)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    Haptics.selection()
                    viewModel.runRegulator()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                        Text("REGULATE")
                            .font(.caption2.weight(.black))
                            .fontDesign(.monospaced)
                    }
                    .foregroundColor(isDarkMode ? Color(hex: "#020617") : Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isDarkMode ? toneColor(for: .cyan).opacity(0.92) : Color(hex: "#0EA5E9"))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isDarkMode ? toneColor(for: .cyan).opacity(0.25) : Color(hex: "#0369A1").opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.selection()
                    withAnimation(reduceMotion ? .none : Theme.Animation.context) {
                        boardMode = boardMode == .focusToday ? .expandedWeek : .focusToday
                    }
                } label: {
                    ZStack {
                        Image(systemName: boardMode == .expandedWeek ? "rectangle.split.3x1.fill" : "rectangle.split.3x1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textMain)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.85))
                            )
                            .overlay(
                                Circle()
                                    .stroke(isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(boardMode == .expandedWeek ? "Focus today" : "Expand week")
            }
        }
    }

    @ViewBuilder
    var calendarConnectionBanner: some View {
        calendarConnectionBannerContent
    }

    var calendarConnectionBannerContent: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isCalendarConnected ? toneColor(for: .cyan) : Color(hex: "F59E0B"))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.calendarStatusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(textMuted)
            }

            Spacer(minLength: 8)

            if viewModel.isCalendarConnected == false {
                Button {
                    Haptics.selection()
                    handleCalendarButtonTap()
                } label: {
                    Text(calendarActionLabel)
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(calendarActionForeground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(calendarActionBackground))
                        .overlay(
                            Capsule()
                                .stroke(calendarActionStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, viewModel.isCalendarConnected ? 32 : 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(calendarBannerBackground))
        .overlay(
            Capsule()
                .stroke(calendarBannerStroke, lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            if viewModel.isCalendarConnected {
                dismissIconButton(
                    action: dismissCalendarConnectedBanner,
                    accessibilityLabel: "Dismiss calendar connection message" // [VERIFY]
                )
                .padding(.trailing, 2)
            }
        }
    }

    var calendarActionForeground: Color {
        isDarkMode ? toneColor(for: .cyan) : Color(hex: "#0369A1")
    }

    var calendarActionBackground: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.92)
    }

    var calendarActionStroke: Color {
        isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }

    var calendarBannerBackground: Color {
        isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.8)
    }

    var calendarBannerStroke: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.07)
    }

    var calendarActionLabel: String {
        switch viewModel.calendarAccessStatus {
        case .notDetermined:
            return "CONNECT"
        case .denied, .restricted, .writeOnly:
            return "SETTINGS"
        case .authorized:
            return "CONNECTED"
        }
    }

    //codex TODO move to viewModel
    func handleCalendarButtonTap() {
        switch viewModel.calendarAccessStatus {
        case .authorized, .notDetermined:
            Task {
                await viewModel.requestCalendarAccess()
                if viewModel.isCalendarConnected {
                    Haptics.success()
                } else {
                    Haptics.warning()
                }
            }
        case .denied, .restricted, .writeOnly:
            Haptics.warning()
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
        }
    }

    var queueSection: some View {
        let totalAvailable = viewModel.queueItems.reduce(0) { $0 + $1.remainingCount }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("QUEUE : PROTOCOLS")
                    .font(.caption.weight(.bold))
                    .fontDesign(.monospaced)
                    .tracking(1.3)
                    .foregroundColor(textMuted)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "FACC15"))
                        .frame(width: 7, height: 7)
                    Text("\(totalAvailable) AVAILABLE")
                        .font(.caption.weight(.bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(textMain.opacity(0.78))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
            }

            Text("Drag onto a slot, tap to arm placement, or use ••• to edit time preference and duration.")
                .font(.caption.weight(.semibold))
                .foregroundColor(textSubtle)

            if viewModel.queueItems.isEmpty {
                Text(viewModel.hasTrackableProtocols ? "All scheduled" : "No active protocols")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.queueItems) { item in
                            queueCard(item)
                        }
                    }
                    .padding(.horizontal, 1)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    func queueCard(_ item: PlanQueueItem) -> some View {
        let isSelected = viewModel.selectedQueueProtocolId == item.protocolId
        let tone = toneColor(for: item.tone)
        let payload = PlanDropPayload.queuePayload(for: item.protocolId)
        let isDragging = activeDragPayload == payload

        let primaryContent = HStack(spacing: 10) {
            Image(systemName: resolvedProtocolIcon(item.icon))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(item.isDisabled ? textMuted : tone)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(item.isDisabled ? textMuted : textMain)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(item.isDisabled ? "PAUSED" : "\(item.remainingCount) REMAINING")
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(item.isDisabled ? textMuted : tone)
                    Text(item.durationLabel)
                        .font(.caption2.weight(.bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(textMuted)
                }
            }

            Spacer(minLength: 0)
        }

        let primaryAction = Button {
            Haptics.selection()
            viewModel.selectProtocol(id: item.protocolId)
        } label: {
            primaryContent
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .padding(.trailing, 52)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)

        let secondaryAction = Menu {
            Button {
                Haptics.selection()
                viewModel.openProtocolEditor(protocolId: item.protocolId)
            } label: {
                Label("Edit Protocol", systemImage: "slider.horizontal.3")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textMuted)
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        let card = ZStack(alignment: .trailing) {
            if item.isDisabled {
                primaryAction
            } else {
                primaryAction.draggable(payload) {
                    queueDragPreview(item: item)
                        .onAppear {
                            activeDragPayload = payload
                            if viewModel.selectedQueueProtocolId != item.protocolId {
                                viewModel.selectProtocol(id: item.protocolId)
                            }
                        }
                        .onDisappear {
                            if activeDragPayload == payload {
                                activeDragPayload = nil
                            }
                        }
                }
            }
            secondaryAction
                .padding(.trailing, 6)
        }
        .frame(minWidth: queueCardBaseWidth, maxWidth: queueCardBaseWidth + 32, alignment: .leading)
        .background(glassCard(cornerRadius: 16))
        .scaleEffect(isDragging ? 1.02 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? tone.opacity(0.78) : (item.isDisabled ? Color.gray.opacity(0.2) : Color.clear),
                    lineWidth: isSelected ? 1.4 : 1
                )
        )
        .shadow(
            color: isDragging ? tone.opacity(isDarkMode ? 0.42 : 0.2) : .clear,
            radius: isDragging ? 12 : 0,
            x: 0,
            y: 0
        )
        .opacity(item.isDisabled ? 0.65 : 1)
        .contextMenu {
            Button {
                Haptics.selection()
                viewModel.openProtocolEditor(protocolId: item.protocolId)
            } label: {
                Label("Edit Protocol", systemImage: "slider.horizontal.3")
            }
        }
        card
    }

    var todayAtGlanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY AT A GLANCE")
                .font(.caption.weight(.bold))
                .fontDesign(.monospaced)
                .tracking(1.3)
                .foregroundColor(textMuted)

            HStack(spacing: 10) {
                glanceMetric(title: "Busy", value: minutesString(viewModel.todaySummary.busyMinutes), tone: .amber)
                glanceMetric(title: "Free", value: minutesString(viewModel.todaySummary.freeMinutes), tone: .cyan)
                glanceMetric(title: "Planned", value: "\(viewModel.todaySummary.plannedCount)", tone: .indigo)
                glanceMetric(title: "Remaining", value: "\(viewModel.todaySummary.remainingSessions)", tone: .purple)
            }
        }
        .padding(12)
        .background(glassCard(cornerRadius: 18))
    }

    func glanceMetric(title: String, value: String, tone: PlanTone) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .fontDesign(.monospaced)
                .foregroundColor(textSubtle)
            Text(value)
                .font(.callout.weight(.black))
                .fontDesign(.monospaced)
                .foregroundColor(toneColor(for: tone))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var weekPillars: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: boardMode == .expandedWeek ? 12 : 8) {
                    timeAxisColumn

                    ForEach(Array(viewModel.currentWeekDays.enumerated()), id: \.element.id) { index, day in
                        let visible = revealedDayIds.contains(day.id)
                        dayColumn(day)
                            .id(day.id)
                            .opacity(visible ? 1 : 0)
                            .scaleEffect(visible ? 1 : 0.92)
                            .offset(x: visible ? 0 : 34)
                            .animation(
                                reduceMotion
                                    ? .none
                                    : Theme.Animation.content.delay(Double(max(viewModel.currentWeekDays.count - index - 1, 0)) * 0.06),
                                value: visible
                            )
                            .animation(reduceMotion ? .none : Theme.Animation.context, value: boardMode)
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                centerActiveDay(using: proxy)
                runColumnEntranceIfNeeded()
            }
            .onChange(of: viewModel.currentWeekDays.map(\.id)) { _ in
                centerActiveDay(using: proxy)
                runColumnEntranceIfNeeded()
            }
            .onChange(of: boardMode) { _ in
                centerActiveDay(using: proxy)
            }
        }
    }

    var timeAxisColumn: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 34)
            ForEach(PlanSlot.allCases) { slot in
                VStack(spacing: 3) {
                    Text(slot.title)
                        .font(.caption.weight(.bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(textSubtle)
                    Text(slot.durationHoursLabel)
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(textSubtle.opacity(0.72))
                }
                .frame(width: 30, height: slotHeight(isCompact: false))
            }
        }
    }

    func dayColumn(_ day: PlanDayModel) -> some View {
        let isCompact = boardMode == .focusToday && day.isToday == false
        let width = dayWidth(for: day, isCompact: isCompact)

        return VStack(spacing: 6) {
            VStack(spacing: 1) {
                Text(day.weekdayLabel)
                    .font(day.isToday ? .footnote.weight(.bold) : .caption.weight(.bold))
                    .fontDesign(.monospaced)
                    .tracking(0.8)
                    .foregroundColor(day.isToday ? todayAccent : textSubtle)
                if day.isCompactEligible == false || boardMode == .expandedWeek {
                    Text(day.dayNumberLabel)
                        .font(day.isToday ? .callout.weight(.black) : .caption.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(day.isToday ? todayAccent : textMuted)
                }
            }
            .frame(height: 34)

            VStack(spacing: 8) {
                ForEach(day.slots) { slot in
                    slotCard(day: day, slot: slot, isCompact: isCompact)
                }
            }
            .padding(6)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: day.isToday ? 18 : 14, style: .continuous)
                    .fill(day.isToday ? todayColumnBackground : columnBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: day.isToday ? 18 : 14, style: .continuous)
                    .stroke(day.isToday ? todayAccent.opacity(0.5) : columnStroke, lineWidth: day.isToday ? 1.6 : 1)
                    .shadow(color: day.isToday ? todayAccent.opacity(isDarkMode ? 0.35 : 0.15) : .clear, radius: 8, x: 0, y: 0)
            )

            if day.isToday {
                Text("TODAY")
                    .font(.caption2.weight(.black))
                    .fontDesign(.monospaced)
                    .foregroundColor(isDarkMode ? Color(hex: "020617") : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(day.isToday ? todayAccent : Color.gray))
            }
        }
    }

    func slotCard(day: PlanDayModel, slot: PlanSlotModel, isCompact: Bool) -> some View {
        let dropFeedback = dropFeedback(for: day, slot: slot)
        let draftItems = viewModel.draftAllocations(for: day.date, slot: slot.slot)

        return Group {
            if isCompact {
                compactSlotCard(day: day, slot: slot, feedback: dropFeedback, draftItems: draftItems)
            } else {
                expandedSlotCard(day: day, slot: slot, feedback: dropFeedback, draftItems: draftItems)
            }
        }
        .frame(minHeight: slotHeight(isCompact: isCompact), alignment: .top)
        .overlay(alignment: .topLeading) {
            if let message = dropFeedback.message {
                Text(message)
                    .font(.caption2.weight(.black))
                    .fontDesign(.monospaced)
                    .foregroundColor(dropFeedback.isAllowed ? toneColor(for: .cyan) : Color(hex: "EF4444"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isDarkMode ? Color.black.opacity(0.6) : Color.white.opacity(0.92))
                    )
                    .padding(6)
            }
        }
        .overlay {
            if dropFeedback.isTargeted, let preview = dragPreview(for: day, slot: slot) {
                RoundedRectangle(cornerRadius: isCompact ? 12 : 10, style: .continuous)
                    .fill(toneColor(for: preview.tone).opacity(isDarkMode ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 12 : 10, style: .continuous)
                            .stroke(
                                dropFeedback.isAllowed ? toneColor(for: preview.tone).opacity(0.7) : Color(hex: "EF4444").opacity(0.75),
                                style: StrokeStyle(lineWidth: 1.3, dash: [5, 3])
                            )
                    )
                    .overlay(alignment: .center) {
                        VStack(spacing: 4) {
                            Text(preview.title.uppercased())
                                .font(.caption2.weight(.black))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(preview.durationLabel)
                                .font(.caption2.weight(.bold))
                                .fontDesign(.monospaced)
                        }
                        .foregroundColor(dropFeedback.isAllowed ? toneColor(for: preview.tone) : Color(hex: "EF4444"))
                    }
                    .opacity(dropFeedback.isTargeted ? 0.92 : 1)
                    .padding(isCompact ? 5 : 8)
            }
        }
        .dropDestination(
            for: String.self,
            action: { items, _ in
                guard let payload = items.first else { return false }
                activeDragPayload = payload
                return handleDrop(payload: payload, day: day.date, slot: slot.slot)
            },
            isTargeted: { isTargeted in
                updateTargetedSlot(slot.id, isTargeted: isTargeted)
            }
        )
    }

    func compactSlotCard(
        day: PlanDayModel,
        slot: PlanSlotModel,
        feedback: PlanSlotDropFeedback,
        draftItems: [PlanAllocationDraft]
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    slotStrokeColor(slot: slot, feedback: feedback, inCompact: true),
                    style: StrokeStyle(lineWidth: feedback.isTargeted ? 1.4 : 1, dash: slot.busyMinutes > 0 ? [4, 3] : [5, 4])
                )

            if let first = slot.allocations.first {
                let isRecentlyLocked = isRecentlyLockedAllocation(protocolId: first.protocolId, day: day.date, slot: slot.slot)
                let isPaused = first.status == .paused
                let baseChip = Button {
                    viewModel.editAllocation(allocationId: first.id)
                } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isPaused ? pausedAllocationFill : allocationFill(for: first.tone))
                        .overlay(
                            Image(systemName: first.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isPaused ? textMuted : allocationTextColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    toneColor(for: first.tone).opacity(isRecentlyLocked ? (lockInPulseActive ? 0.95 : 0.55) : 0),
                                    lineWidth: isRecentlyLocked ? (lockInPulseActive ? 1.8 : 1.1) : 0
                                )
                        )
                        .shadow(
                            color: toneColor(for: first.tone).opacity(isRecentlyLocked ? (lockInPulseActive ? 0.45 : 0.22) : 0),
                            radius: isRecentlyLocked ? (lockInPulseActive ? 14 : 8) : 0,
                            x: 0,
                            y: 0
                        )
                        .scaleEffect(isRecentlyLocked ? (lockInPulseActive ? 1.045 : 1.0) : 1)
                        .animation(reduceMotion ? .none : Theme.Animation.snappy, value: lockInPulseActive)
                        .overlay(alignment: .topTrailing) {
                            if slot.allocations.count > 1 {
                                Text("\(slot.allocations.count)")
                                    .font(.caption2.weight(.black))
                                    .fontDesign(.monospaced)
                                    .foregroundColor(isPaused ? textMuted : allocationTextColor)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.black.opacity(0.2)))
                                    .padding(5)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if isRecentlyLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(isPaused ? textMuted : allocationTextColor)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(toneColor(for: first.tone).opacity(isDarkMode ? 0.32 : 0.24))
                                    )
                                    .padding(5)
                            }
                        }
                        .padding(6)
                }
                .buttonStyle(.plain)
                .disabled(first.status.isInteractive == false)
                .opacity(first.status.isInteractive ? 1 : 0.6)
                .overlay(alignment: .bottomLeading) {
                    if first.status.isInteractive == false {
                        Text(first.status == .paused ? "PAUSED" : "SKIPPED")
                            .font(.caption2.weight(.black))
                            .fontDesign(.monospaced)
                            .foregroundColor(allocationTextColor.opacity(0.9))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(isDarkMode ? 0.32 : 0.16))
                            )
                            .padding(7)
                    }
                }

                if first.status.isInteractive {
                    baseChip.draggable(PlanDropPayload.allocationPayload(for: first.id)) {
                        allocationDragPreview(allocation: first)
                            .onAppear {
                                activeDragPayload = PlanDropPayload.allocationPayload(for: first.id)
                            }
                            .onDisappear {
                                if activeDragPayload == PlanDropPayload.allocationPayload(for: first.id) {
                                    activeDragPayload = nil
                                }
                            }
                    }
                } else {
                    baseChip
                }
            } else if draftItems.first != nil {
                draftPreviewBadge(title: "DRAFT", tone: toneColor(for: .cyan), icon: "sparkles")
                    .padding(6)
            } else if slot.freeMinutes > 0 {
                Button {
                    if let mutation = viewModel.placeSelectedProtocol(day: day.date, slot: slot.slot) {
                        Haptics.success()
                        showToast(for: mutation)
                    } else {
                        Haptics.warning()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(feedback.isAllowed ? todayAccent.opacity(0.75) : todayAccent.opacity(0.45))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(activeDragPayload == nil)
            }
        }
        .shadow(
            color: feedback.isTargeted && feedback.isAllowed ? todayAccent.opacity(isDarkMode ? 0.35 : 0.16) : .clear,
            radius: feedback.isTargeted ? 8 : 0,
            x: 0,
            y: 0
        )
    }

    func expandedSlotCard(
        day: PlanDayModel,
        slot: PlanSlotModel,
        feedback: PlanSlotDropFeedback,
        draftItems: [PlanAllocationDraft]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Text(slot.slot.title)
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(textSubtle)
                    Text(slot.slot.durationHoursLabel)
                        .font(.caption2.weight(.bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(textSubtle.opacity(0.7))
                }
                Spacer()
                Text(slot.availableLabel)
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(slot.freeMinutes > 0 ? textMuted : Color(hex: "F59E0B"))
            }

            if slot.busyMinutes > 0 {
                Text("BUSY \(minutesString(slot.busyMinutes))")
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
            }

            let eventEntries = busyEventEntries(day: day, slot: slot)
            if eventEntries.isEmpty == false {
                VStack(spacing: 8) {
                    ForEach(eventEntries) { entry in
                        busyEventChip(entry)
                    }
                }
            }

            ForEach(slot.allocations) { allocation in
                if allocation.status.isInteractive {
                    allocationChip(allocation, day: day.date, slot: slot.slot)
                        .draggable(PlanDropPayload.allocationPayload(for: allocation.id)) {
                            allocationDragPreview(allocation: allocation)
                                .onAppear {
                                    activeDragPayload = PlanDropPayload.allocationPayload(for: allocation.id)
                                }
                                .onDisappear {
                                    if activeDragPayload == PlanDropPayload.allocationPayload(for: allocation.id) {
                                        activeDragPayload = nil
                                    }
                                }
                        }
                } else {
                    allocationChip(allocation, day: day.date, slot: slot.slot)
                }
            }

            ForEach(Array(draftItems.enumerated()), id: \.offset) { _, draft in
                draftAllocationChip(draft)
            }

            if slot.freeMinutes > 0 {
                let isDragInProgress = activeDragPayload != nil
                Button {
                    if let mutation = viewModel.placeSelectedProtocol(day: day.date, slot: slot.slot) {
                        Haptics.success()
                        showToast(for: mutation)
                    } else {
                        Haptics.warning()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(
                            feedback.message == nil
                                ? (isDragInProgress ? "DROP HERE" : "TAP TO PLACE")
                                : "UNAVAILABLE"
                        )
                            .font(.caption2.weight(.black))
                            .fontDesign(.monospaced)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(
                        feedback.message == nil
                            ? (isDarkMode ? Color(hex: "00F2FF").opacity(0.7) : Color(hex: "0EA5E9").opacity(0.8))
                            : Color(hex: "EF4444").opacity(0.75)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .frame(minHeight: 44)
                    .background(availableBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                slotStrokeColor(slot: slot, feedback: feedback, inCompact: false),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isDragInProgress == false)
            } else if slot.allocations.isEmpty {
                Text("FULL")
                    .font(.caption2.weight(.black))
                    .fontDesign(.monospaced)
                    .foregroundColor(textSubtle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(availableBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(glassCard(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(slotStrokeColor(slot: slot, feedback: feedback, inCompact: false), lineWidth: feedback.isTargeted ? 1.4 : 1)
        )
        .shadow(
            color: feedback.isTargeted && feedback.isAllowed ? todayAccent.opacity(isDarkMode ? 0.28 : 0.12) : .clear,
            radius: feedback.isTargeted ? 9 : 0,
            x: 0,
            y: 0
        )
    }

    func allocationChip(_ allocation: PlanAllocationDisplay, day: Date, slot: PlanSlot) -> some View {
        let isRecentlyLocked = isRecentlyLockedAllocation(protocolId: allocation.protocolId, day: day, slot: slot)
        let isInteractive = allocation.status.isInteractive
        let isPaused = allocation.status == .paused
        return Button {
            viewModel.editAllocation(allocationId: allocation.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: resolvedProtocolIcon(allocation.icon))
                    .font(.system(size: 10, weight: .bold))
                VStack(alignment: .leading, spacing: 3) {
                    Text(allocation.title.uppercased())
                        .font(.caption.weight(.black))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(allocation.durationLabel)
                        .font(.caption2.weight(.bold))
                        .fontDesign(.monospaced)
                }
                Spacer(minLength: 0)
            }
            .foregroundColor(isPaused ? textMuted : allocationTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(allocationBackground(tone: allocation.tone, isPaused: isPaused))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        (isPaused ? pausedAllocationStroke : toneColor(for: allocation.tone))
                            .opacity(isRecentlyLocked ? (lockInPulseActive ? 0.96 : 0.68) : (isDarkMode ? 0.6 : 0.45)),
                        lineWidth: isRecentlyLocked ? (lockInPulseActive ? 1.9 : 1.3) : 1
                    )
            )
            .overlay(alignment: .trailing) {
                if isRecentlyLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .black))
                        Text("LOCKED")
                            .font(.caption2.weight(.black))
                            .fontDesign(.monospaced)
                    }
                    .foregroundColor(allocationTextColor.opacity(0.95))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(toneColor(for: allocation.tone).opacity(isDarkMode ? 0.28 : 0.22))
                    )
                    .padding(.trailing, 5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(
                color: toneColor(for: allocation.tone).opacity(isRecentlyLocked ? (lockInPulseActive ? 0.48 : 0.22) : 0),
                radius: isRecentlyLocked ? (lockInPulseActive ? 16 : 8) : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(isRecentlyLocked ? (lockInPulseActive ? 1.03 : 1.0) : 1)
            .animation(reduceMotion ? .none : Theme.Animation.snappy, value: lockInPulseActive)
            .overlay(alignment: .bottomLeading) {
                if isInteractive == false {
                    Text(allocation.status == .paused ? "PAUSED" : "SKIPPED")
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                        .foregroundColor(allocationTextColor.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(isDarkMode ? 0.3 : 0.12))
                        )
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isInteractive == false)
        .opacity(isInteractive ? 1 : 0.62)
    }

    func draftPreviewBadge(title: String, tone: Color, icon: String) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(tone.opacity(isDarkMode ? 0.10 : 0.07))
            .overlay(
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(title)
                        .font(.caption2.weight(.black))
                        .fontDesign(.monospaced)
                }
                .foregroundColor(tone.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tone.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            )
    }

    func draftAllocationChip(_ draft: PlanAllocationDraft) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            VStack(alignment: .leading, spacing: 3) {
                Text((viewModel.protocolTitle(for: draft.protocolId)).uppercased())
                    .font(.caption.weight(.black))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(draft.durationMinutes)m DRAFT")
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
            }
            Spacer(minLength: 0)
        }
        .foregroundColor(toneColor(for: .cyan))
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(toneColor(for: .cyan).opacity(isDarkMode ? 0.11 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(toneColor(for: .cyan).opacity(0.8), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
        )
    }

    func busyEventChip(_ entry: BusyEventEntry) -> some View {
        HStack(spacing: 7) {
            Image(systemName: entry.isContinuation ? "arrow.turn.down.right" : "calendar")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color.white.opacity(0.88))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.uppercased())
                    .font(.caption2.weight(.black))
                    .fontDesign(.monospaced)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(eventTimeRangeLabel(entry.event))
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .foregroundColor(Color.white.opacity(0.94))
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1F2937"), Color(hex: "030712")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            if entry.continuesFromPrevious {
                Capsule(style: .continuous)
                    .fill(Color(hex: "111827"))
                    .frame(width: 3, height: 7)
                    .offset(y: -5)
            }
        }
        .overlay(alignment: .bottom) {
            if entry.continuesToNext {
                Capsule(style: .continuous)
                    .fill(Color(hex: "111827"))
                    .frame(width: 3, height: 7)
                    .offset(y: 5)
            }
        }
    }

    var distributionStatus: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.structureStatus.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(structureColor)
                Text(viewModel.structureStatus.title)
                    .font(.footnote.weight(.black))
                    .fontDesign(.monospaced)
                    .tracking(1.1)
                    .foregroundColor(textMain.opacity(0.85))
            }
            Text(viewModel.structureMessage)
                .font(.caption.weight(.semibold))
                .foregroundColor(textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
    }

    var legend: some View {
        HStack {
            legendItem(color: toneColor(for: .cyan), label: "Protocol")
            legendItem(color: textSubtle.opacity(0.5), label: "Busy")
            legendItem(color: textSubtle.opacity(0.3), label: "Gap")
            legendItem(color: Color(hex: "F59E0B").opacity(0.65), label: "Fragile")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(glassCard(cornerRadius: 16))
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .fontDesign(.monospaced)
                .foregroundColor(textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    var boardScrollHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 10, weight: .bold))
            Text("Swipe left or right to see all days")
                .font(.caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundColor(textMuted)
        .padding(.leading, 10)
        .padding(.trailing, 32)
        .padding(.vertical, 7)
        .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.86)))
        .overlay(
            Capsule()
                .stroke(isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            dismissIconButton(
                action: dismissBoardHint,
                accessibilityLabel: "Dismiss swipe hint" // [VERIFY]
            )
            .padding(.trailing, 2)
        }
        .accessibilityElement(children: .contain)
    }

    func dismissBoardHint() {
        withAnimation(reduceMotion ? nil : Theme.Animation.context) {
            didDismissPlanBoardHintSessionID = effectiveMotionSessionID
        }
    }

    func dismissCalendarConnectedBanner() {
        withAnimation(reduceMotion ? nil : Theme.Animation.context) {
            didDismissPlanCalendarConnectedBannerSessionID = effectiveMotionSessionID
        }
    }

    func dismissIconButton(action: @escaping () -> Void, accessibilityLabel: String) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(textSubtle)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
    }

    func queueDragPreview(item: PlanQueueItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: resolvedProtocolIcon(item.icon))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(toneColor(for: item.tone))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.uppercased())
                    .font(.caption2.weight(.black))
                Text(item.durationLabel)
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
            }
            .foregroundColor(textMain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(glassCard(cornerRadius: 12))
    }

    func allocationDragPreview(allocation: PlanAllocationDisplay) -> some View {
        HStack(spacing: 8) {
            Image(systemName: resolvedProtocolIcon(allocation.icon))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(toneColor(for: allocation.tone))
            VStack(alignment: .leading, spacing: 2) {
                Text(allocation.title.uppercased())
                    .font(.caption2.weight(.black))
                Text(allocation.durationLabel)
                    .font(.caption2.weight(.bold))
                    .fontDesign(.monospaced)
            }
            .foregroundColor(textMain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(glassCard(cornerRadius: 12))
    }

    func updateTargetedSlot(_ slotId: String, isTargeted: Bool) {
        if isTargeted {
            targetedSlotId = slotId
        } else if targetedSlotId == slotId {
            targetedSlotId = nil
        }
    }

    func dropFeedback(for day: PlanDayModel, slot: PlanSlotModel) -> PlanSlotDropFeedback {
        let isTargeted = targetedSlotId == slot.id
        guard let activeDragPayload else {
            if let selectedProtocolId = viewModel.selectedQueueProtocolId {
                let validation = viewModel.validateProtocolPlacement(protocolId: selectedProtocolId, day: day.date, slot: slot.slot)
                return PlanSlotDropFeedback(
                    isTargeted: false,
                    isAllowed: validation.isAllowed,
                    message: nil
                )
            }
            return PlanSlotDropFeedback(isTargeted: false, isAllowed: slot.freeMinutes > 0, message: nil)
        }

        guard isTargeted else {
            return PlanSlotDropFeedback(isTargeted: false, isAllowed: true, message: nil)
        }

        if let protocolId = PlanDropPayload.protocolId(from: activeDragPayload) {
            let validation = viewModel.validateProtocolPlacement(protocolId: protocolId, day: day.date, slot: slot.slot)
            return PlanSlotDropFeedback(
                isTargeted: true,
                isAllowed: validation.isAllowed,
                message: validation.message
            )
        }

        if let allocationId = PlanDropPayload.allocationId(from: activeDragPayload) {
            let validation = viewModel.validateMove(allocationId: allocationId, day: day.date, slot: slot.slot)
            return PlanSlotDropFeedback(
                isTargeted: true,
                isAllowed: validation.isAllowed,
                message: validation.message
            )
        }

        return PlanSlotDropFeedback(
            isTargeted: true,
            isAllowed: false,
            message: "Unsupported drop"
        )
    }

    func slotStrokeColor(slot: PlanSlotModel, feedback: PlanSlotDropFeedback, inCompact: Bool) -> Color {
        if feedback.isTargeted {
            return feedback.isAllowed ? toneColor(for: .cyan).opacity(0.8) : Color(hex: "EF4444").opacity(0.78)
        }
        if feedback.isAllowed, viewModel.selectedQueueProtocolId != nil, slot.freeMinutes > 0 {
            return toneColor(for: .cyan).opacity(inCompact ? 0.26 : 0.34)
        }
        if slot.busyMinutes > 0 {
            return isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
        }
        return slot.freeMinutes > 0 ? todayAccent.opacity(0.22) : Color.clear
    }

    func dragPreview(for day: PlanDayModel, slot: PlanSlotModel) -> PlanDragPreview? {
        guard targetedSlotId == slot.id, let activeDragPayload else { return nil }

        if let protocolId = PlanDropPayload.protocolId(from: activeDragPayload),
           let queueItem = viewModel.queueItem(for: protocolId) {
            return PlanDragPreview(
                title: queueItem.title,
                durationLabel: queueItem.durationLabel,
                tone: queueItem.tone
            )
        }

        if let allocationId = PlanDropPayload.allocationId(from: activeDragPayload),
           let allocation = viewModel.allocationDisplay(for: allocationId) {
            return PlanDragPreview(
                title: allocation.title,
                durationLabel: allocation.durationLabel,
                tone: allocation.tone
            )
        }

        return nil
    }

    func handleDrop(payload: String, day: Date, slot: PlanSlot) -> Bool {
        defer {
            activeDragPayload = nil
            targetedSlotId = nil
        }

        if let protocolId = PlanDropPayload.protocolId(from: payload) {
            guard let mutation = viewModel.placeProtocol(protocolId: protocolId, day: day, slot: slot) else {
                Haptics.warning()
                return false
            }
            Haptics.success()
            showToast(for: mutation)
            return true
        }

        if let allocationId = PlanDropPayload.allocationId(from: payload) {
            guard let mutation = viewModel.moveAllocation(allocationId: allocationId, to: day, slot: slot) else {
                Haptics.warning()
                return false
            }
            Haptics.success()
            showToast(for: mutation)
            return true
        }

        Haptics.warning()
        return false
    }

    func showToast(for mutation: PlanMutation) {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"

        switch mutation {
        case .placed(let allocationId, let title, let day, let slot):
            pendingUndo = .remove(allocationId: allocationId)
            toast = PlanToast(
                message: "\(title) scheduled on \(formatter.string(from: day).uppercased()) \(slot.title)",
                undoLabel: "Undo"
            )
        case .moved(let allocationId, let title, let fromDay, let fromSlot, let toDay, let toSlot):
            pendingUndo = .move(allocationId: allocationId, day: fromDay, slot: fromSlot)
            toast = PlanToast(
                message: "\(title) moved to \(formatter.string(from: toDay).uppercased()) \(toSlot.title)",
                undoLabel: "Undo"
            )
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_800_000_000)
            if toast != nil {
                toast = nil
                pendingUndo = nil
            }
        }
    }

    func applyUndo() {
        guard let pendingUndo else { return }

        switch pendingUndo {
        case .remove(let allocationId):
            viewModel.removeAllocation(allocationId: allocationId)
        case .move(let allocationId, let day, let slot):
            _ = viewModel.moveAllocation(allocationId: allocationId, to: day, slot: slot)
        }

        toast = nil
        self.pendingUndo = nil
    }

    func planToastView(_ toast: PlanToast) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.callout.weight(.bold))
                .foregroundColor(toneColor(for: .cyan))

            Text(toast.message)
                .font(.footnote.weight(.semibold))
                .foregroundColor(textMain)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(.regularMaterial)
                        .opacity(isDarkMode ? 0.52 : 0.62)
                )

            Spacer(minLength: 0)

            Button(toast.undoLabel) {
                Haptics.selection()
                applyUndo()
            }
            .font(.caption.weight(.black))
            .fontDesign(.monospaced)
            .foregroundColor(toneColor(for: .cyan))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(glassCard(cornerRadius: 14))
    }

    func centerActiveDay(using proxy: ScrollViewProxy) {
        guard let activeDayId = (viewModel.currentWeekDays.first(where: { $0.isToday }) ?? viewModel.currentWeekDays.first)?.id else {
            return
        }
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                proxy.scrollTo(activeDayId, anchor: .center)
            }
        }
    }

    func handleExternalPlanFocus(_ protocolId: UUID?) {
        guard let protocolId else { return }
        viewModel.focusProtocol(id: protocolId)
        withAnimation(reduceMotion ? .none : Theme.Animation.context) {
            boardMode = .expandedWeek
        }
        router.consumePlanFocusIntent()
    }

    func handleExternalPlanEdit(_ protocolId: UUID?) {
        guard let protocolId else { return }
        viewModel.openProtocolEditor(protocolId: protocolId)
        withAnimation(reduceMotion ? .none : Theme.Animation.context) {
            boardMode = .expandedWeek
        }
        router.consumePlanEditIntent()
    }

    func runColumnEntranceIfNeeded() {
        let dayIds = viewModel.currentWeekDays.map(\.id)
        guard dayIds.isEmpty == false else { return }

        if didRunColumnEntrance {
            let allVisible = Set(dayIds)
            if revealedDayIds != allVisible {
                revealedDayIds = allVisible
            }
            return
        }

        didRunColumnEntrance = true
        if reduceMotion || didAnimateColumnsThisSession {
            revealedDayIds = Set(dayIds)
            didAnimatePlanColumnsSessionID = effectiveMotionSessionID
            return
        }

        revealedDayIds.removeAll()
        for (index, dayId) in dayIds.enumerated() {
            let reverseIndex = dayIds.count - index - 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(reverseIndex) * 0.06) {
                revealedDayIds.insert(dayId)
            }
        }
        let settleDelay = Double(max(dayIds.count - 1, 0)) * 0.06 + 0.10
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
            didAnimatePlanColumnsSessionID = effectiveMotionSessionID
        }
    }

    func triggerRegulatorLockInAnimation(for draftAllocations: [PlanAllocationDraft]) {
        let keys = Set(
            draftAllocations.map {
                allocationAnimationKey(protocolId: $0.protocolId, day: $0.day, slot: planSlot(from: $0.slot))
            }
        )
        guard keys.isEmpty == false else { return }

        recentlyLockedAllocationKeys = keys
        lockInPulseActive = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(reduceMotion ? .none : Theme.Animation.snappy) {
                lockInPulseActive = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            withAnimation(reduceMotion ? .none : Theme.Animation.content) {
                lockInPulseActive = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            recentlyLockedAllocationKeys.subtract(keys)
        }
    }

    func isRecentlyLockedAllocation(protocolId: UUID, day: Date, slot: PlanSlot) -> Bool {
        recentlyLockedAllocationKeys.contains(
            allocationAnimationKey(protocolId: protocolId, day: day, slot: slot)
        )
    }

    func allocationAnimationKey(protocolId: UUID, day: Date, slot: PlanSlot) -> String {
        let dayStart = DateRules.startOfDay(day, calendar: DateRules.isoCalendar)
        return "\(protocolId.uuidString)|\(Int(dayStart.timeIntervalSince1970))|\(slot.rawValue)"
    }

    func planSlot(from regulationSlot: RegulationSlot) -> PlanSlot {
        switch regulationSlot {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }

    func dayWidth(for day: PlanDayModel, isCompact: Bool) -> CGFloat {
        if isCompact { return compactDayWidth }
        if boardMode == .expandedWeek { return regularDayWidth }
        if day.isToday { return todayDayWidth }
        return compactDayWidth
    }

    func slotHeight(isCompact: Bool) -> CGFloat {
        isCompact ? compactSlotHeight : expandedSlotHeight
    }

    func allocationFill(for tone: PlanTone) -> Color {
        toneColor(for: tone).opacity(isDarkMode ? 0.22 : 0.18)
    }

    func resolvedProtocolIcon(_ raw: String) -> String {
        ProtocolIconCatalog.resolvedSymbolName(raw, fallback: "bolt.fill")
    }

    func minutesString(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    func eventTimeRangeLabel(_ event: PlanCalendarEvent) -> String {
        if event.isAllDay {
            return "ALL DAY"
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: event.startDateTime)
        let end = formatter.string(from: event.endDateTime)
        return "\(start) - \(end)"
    }

    func busyEventEntries(day: PlanDayModel, slot: PlanSlotModel) -> [BusyEventEntry] {
        guard let slotInterval = slot.slot.interval(on: day.date, calendar: DateRules.isoCalendar) else { return [] }

        return slot.busyEvents.compactMap { event in
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            let overlaps = eventInterval.intersects(slotInterval)
                || (eventInterval.start == slotInterval.end && eventInterval.end > slotInterval.end)
                || (eventInterval.end == slotInterval.start && eventInterval.start < slotInterval.start)
            guard overlaps else { return nil }

            let firstSlot = firstVisibleSlot(for: event, on: day.date)
            let rawTitle = event.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (rawTitle?.isEmpty == false ? rawTitle : nil) ?? "Busy"
            return BusyEventEntry(
                id: "\(event.id.uuidString)-\(slot.slot.rawValue)",
                event: event,
                title: title,
                isContinuation: firstSlot != slot.slot,
                continuesFromPrevious: eventInterval.start < slotInterval.start,
                continuesToNext: eventInterval.end > slotInterval.end
            )
        }
        .sorted { lhs, rhs in
            lhs.event.startDateTime < rhs.event.startDateTime
        }
    }

    func firstVisibleSlot(for event: PlanCalendarEvent, on day: Date) -> PlanSlot? {
        let interval = DateInterval(start: event.startDateTime, end: event.endDateTime)
        for slot in PlanSlot.allCases {
            guard let slotInterval = slot.interval(on: day, calendar: DateRules.isoCalendar) else { continue }
            if interval.intersects(slotInterval) {
                return slot
            }
        }
        return nil
    }

}

private extension PlanDayModel {
    var isCompactEligible: Bool { isToday == false }
}

private extension PlanScreen {
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

    func allocationBackground(tone: PlanTone, isPaused: Bool = false) -> some View {
        let fill = isPaused ? pausedAllocationFill : toneColor(for: tone).opacity(isDarkMode ? 0.16 : 0.14)
        let shadowColor = isPaused ? Color.clear : toneColor(for: tone).opacity(isDarkMode ? 0.28 : 0.18)
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(fill)
            .shadow(
                color: shadowColor,
                radius: isDarkMode ? 10 : 6,
                x: 0,
                y: 0
            )
    }

    var pausedAllocationFill: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    var pausedAllocationStroke: Color {
        isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.24)
    }

    var allocationTextColor: Color {
        isDarkMode ? .white : Color(hex: "0F172A")
    }
}

private struct PlanSlotDropFeedback {
    let isTargeted: Bool
    let isAllowed: Bool
    let message: String?
}

private struct PlanDragPreview {
    let title: String
    let durationLabel: String
    let tone: PlanTone
}

private struct BusyEventEntry: Identifiable {
    let id: String
    let event: PlanCalendarEvent
    let title: String
    let isContinuation: Bool
    let continuesFromPrevious: Bool
    let continuesToNext: Bool
}

private struct PlanWarningBannerView: View {
    let title: String?
    let message: String
    let hint: String?
    let isDarkMode: Bool

    var body: some View {
        content
            .foregroundColor(foregroundTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(warningSurface)
            .overlay(outerCardStroke)
            .padding(.top, 8)
            .padding(.horizontal, 14)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let title, title.isEmpty == false {
                Text(title.uppercased())
                    .font(.caption2.weight(.black))
                    .fontDesign(.monospaced)
                    .tracking(1.1)
            }

            Text(message)
                .font(.footnote.weight(.semibold))

            if let hint, hint.isEmpty == false {
                Text(hint)
                    .font(.caption.weight(.medium))
                    .foregroundColor(hintTextColor)
            }
        }
    }

    private var foregroundTextColor: Color {
        isDarkMode ? .white : Color(hex: "111827")
    }

    private var hintTextColor: Color {
        (isDarkMode ? Color.white : Color(hex: "111827")).opacity(0.75)
    }

    private var warningSurface: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.thickMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(warningFillColor)
            )
    }

    private var outerCardStroke: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(warningStrokeColor, lineWidth: 1)
    }

    private var warningFillColor: Color {
        isDarkMode ? Color.red.opacity(0.22) : Color.yellow.opacity(0.26)
    }

    private var warningStrokeColor: Color {
        isDarkMode ? Color.red.opacity(0.5) : Color.orange.opacity(0.42)
    }
}

private struct PlanToast {
    let message: String
    let undoLabel: String
}

private enum PlanUndoAction {
    case remove(allocationId: UUID)
    case move(allocationId: UUID, day: Date, slot: PlanSlot)
}

private struct PlanRegulatorSheet: View {
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
                        .font(.title3.weight(.bold))
                    Spacer()
                    Text("\(draftCount) placements ready")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                if suggestions.isEmpty {
                    Text("No recommendations available for this week.")
                        .font(.body.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                } else {
                    List {
                        ForEach(suggestions) { suggestion in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(suggestion.protocolTitle)
                                        .font(.headline.weight(.bold))
                                    Spacer()
                                    Text(suggestion.kindLabel)
                                        .font(.caption2.weight(.black))
                                        .fontDesign(.monospaced)
                                        .foregroundColor(kindColor(suggestion.kind))
                                }
                                Text("\(suggestion.dayLabel) \(suggestion.slotLabel) • \(suggestion.confidenceLabel)")
                                    .font(.caption.weight(.semibold))
                                    .fontDesign(.monospaced)
                                    .foregroundColor(.secondary)
                                Text(suggestion.reason)
                                    .font(.footnote)
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

private struct PlanAllocationEditorSheet: View {
    let allocation: PlanAllocation
    let weekDays: [PlanDayModel]
    let titleForProtocol: (UUID) -> String
    let onMove: (Date, PlanSlot) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date
    @State private var selectedSlot: PlanSlot

    init(
        allocation: PlanAllocation,
        weekDays: [PlanDayModel],
        titleForProtocol: @escaping (UUID) -> String,
        onMove: @escaping (Date, PlanSlot) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.allocation = allocation
        self.weekDays = weekDays
        self.titleForProtocol = titleForProtocol
        self.onMove = onMove
        self.onRemove = onRemove
        _selectedDay = State(initialValue: allocation.day)
        _selectedSlot = State(initialValue: allocation.slot)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    Text(titleForProtocol(allocation.protocolId))
                        .font(.headline.weight(.bold))
                }

                Section("Move") {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(weekDays) { day in
                            Text("\(day.weekdayLabel) \(day.dayNumberLabel)").tag(day.date)
                        }
                    }

                    Picker("Slot", selection: $selectedSlot) {
                        ForEach(PlanSlot.allCases) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }

                    Button("Apply Move") {
                        Haptics.success()
                        onMove(selectedDay, selectedSlot)
                        dismiss()
                    }
                }

                Section {
                    Button("Remove Allocation", role: .destructive) {
                        Haptics.success()
                        onRemove()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Allocation")
            .navigationBarTitleDisplayMode(.inline)
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
}

private struct ProtocolSchedulingEditorSheet: View {
    let editor: ProtocolSchedulingEditorState
    let errorMessage: String?
    let onSave: (String, PreferredExecutionSlot, Int, String, NonNegotiableMode?, Int?, Int?) -> Bool
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String
    @State private var selectedIconSystemName: String
    @State private var preferredSlot: PreferredExecutionSlot
    @State private var mode: NonNegotiableMode
    @State private var frequencyPerWeek: Int
    @State private var lockDays: Int
    @State private var selectedDurationPreset: Int?
    @State private var customDurationText: String
    @State private var isUsingCustomDuration: Bool
    @State private var localErrorMessage: String?
    @State private var showingIconPicker = false

    private static let durationPresets: [Int] = [15, 30, 45, 60, 90]

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    private var coreRulesLocked: Bool {
        canEdit(.mode) == false &&
        canEdit(.frequency) == false &&
        canEdit(.lockDuration) == false
    }

    init(
        editor: ProtocolSchedulingEditorState,
        errorMessage: String?,
        onSave: @escaping (String, PreferredExecutionSlot, Int, String, NonNegotiableMode?, Int?, Int?) -> Bool,
        onCancel: @escaping () -> Void
    ) {
        self.editor = editor
        self.errorMessage = errorMessage
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: editor.title)
        _selectedIconSystemName = State(
            initialValue: ProtocolIconCatalog.resolvedSymbolName(
                editor.iconSystemName,
                fallback: NonNegotiableDefinition.defaultIconSystemName(for: editor.mode, title: editor.title)
            )
        )
        _preferredSlot = State(initialValue: editor.preferredExecutionSlot)
        _mode = State(initialValue: editor.mode)
        _frequencyPerWeek = State(initialValue: max(1, min(editor.frequencyPerWeek, 7)))
        _lockDays = State(initialValue: editor.lockDays)

        if Self.durationPresets.contains(editor.estimatedDurationMinutes) {
            _selectedDurationPreset = State(initialValue: editor.estimatedDurationMinutes)
            _customDurationText = State(initialValue: "")
            _isUsingCustomDuration = State(initialValue: false)
        } else {
            _selectedDurationPreset = State(initialValue: nil)
            _customDurationText = State(initialValue: "\(editor.estimatedDurationMinutes)")
            _isUsingCustomDuration = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .disabled(canEdit(.title) == false)
                }
                disabledCaption(for: .title)

                Section("Icon") {
                    Button {
                        Haptics.selection()
                        showingIconPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedIconSystemName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accent)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(accent.opacity(0.15)))
                            Text("Change Protocol Icon")
                                .font(.body.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(canEdit(.icon) == false)
                }
                disabledCaption(for: .icon)

                Section("Core Rules") {
                    Picker("Mode", selection: $mode) {
                        Text("Daily").tag(NonNegotiableMode.daily)
                        Text("Session").tag(NonNegotiableMode.session)
                    }
                    .pickerStyle(.segmented)
                    .tint(coreRulesLocked ? .gray : accent)
                    .disabled(canEdit(.mode) == false)
                    .onChange(of: mode) { newMode in
                        if newMode == .daily {
                            frequencyPerWeek = 7
                        }
                    }

                    Stepper(
                        "\(frequencyPerWeek) / week",
                        value: $frequencyPerWeek,
                        in: 1...7
                    )
                    .disabled(mode == .daily || canEdit(.frequency) == false)

                    HStack(spacing: 8) {
                        ForEach([14, 28], id: \.self) { value in
                            Button("\(value)d") {
                                Haptics.selection()
                                lockDays = value
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(
                                coreRulesLocked
                                    ? .gray.opacity(0.35)
                                    : (lockDays == value ? accent : .gray.opacity(0.3))
                            )
                            .disabled(canEdit(.lockDuration) == false)
                        }
                    }
                }
                .disabled(coreRulesLocked)
                .opacity(coreRulesLocked ? 0.45 : 1.0)
                if mode == .daily {
                    caption("Daily mode is fixed at 7/week.")
                }
                disabledCaption(for: .mode)
                disabledCaption(for: .frequency)
                disabledCaption(for: .lockDuration)

                Section("Preferred Time") {
                    HStack(spacing: 8) {
                        ForEach(PreferredExecutionSlot.allCases, id: \.self) { slot in
                            Button(slot.title) {
                                Haptics.selection()
                                preferredSlot = slot
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(preferredSlot == slot ? accent : .gray.opacity(0.3))
                        }
                    }
                }
                .disabled(canEdit(.preferredTime) == false)
                disabledCaption(for: .preferredTime)

                Section("Duration") {
                    HStack(spacing: 8) {
                        ForEach(Self.durationPresets, id: \.self) { preset in
                            Button("\(preset)m") {
                                Haptics.selection()
                                selectedDurationPreset = preset
                                isUsingCustomDuration = false
                                customDurationText = ""
                                localErrorMessage = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .tint((selectedDurationPreset == preset && isUsingCustomDuration == false) ? accent : .gray.opacity(0.3))
                        }
                    }

                    Toggle("Custom minutes", isOn: $isUsingCustomDuration)
                        .onChange(of: isUsingCustomDuration) { enabled in
                            if enabled {
                                if customDurationText.isEmpty {
                                    customDurationText = "\(selectedDurationPreset ?? editor.estimatedDurationMinutes)"
                                }
                                selectedDurationPreset = nil
                            } else if let parsed = Int(customDurationText), Self.durationPresets.contains(parsed) {
                                selectedDurationPreset = parsed
                            } else {
                                selectedDurationPreset = 60
                            }
                            localErrorMessage = nil
                        }

                    if isUsingCustomDuration {
                        TextField("Minutes (5-360)", text: $customDurationText)
                            .keyboardType(.numberPad)
                    }
                }
                .disabled(canEdit(.estimatedDuration) == false)
                disabledCaption(for: .estimatedDuration)

                if let localErrorMessage {
                    Section {
                        Text(localErrorMessage)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.red)
                    }
                } else if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .tint(accent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        Haptics.selection()
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let durationMinutes = resolvedDurationMinutes() else {
                            localErrorMessage = "Duration must be between 5 and 360 minutes."
                            Haptics.warning()
                            return
                        }

                        let didSave = onSave(
                            title.trimmingCharacters(in: .whitespacesAndNewlines),
                            preferredSlot,
                            durationMinutes,
                            selectedIconSystemName,
                            canEdit(.mode) ? mode : nil,
                            canEdit(.frequency) ? (mode == .daily ? 7 : frequencyPerWeek) : nil,
                            canEdit(.lockDuration) ? lockDays : nil
                        )
                        if didSave {
                            Haptics.success()
                            dismiss()
                        } else {
                            Haptics.warning()
                            localErrorMessage = errorMessage ?? "Unable to update protocol right now."
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                ProtocolIconPickerSheet(
                    protocolTitle: title,
                    initialSelection: selectedIconSystemName,
                    accentColor: accent
                ) { selected in
                    selectedIconSystemName = selected
                }
            }
        }
    }

    private func resolvedDurationMinutes() -> Int? {
        let value: Int
        if isUsingCustomDuration {
            guard let parsed = Int(customDurationText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return nil
            }
            value = parsed
        } else {
            value = selectedDurationPreset ?? editor.estimatedDurationMinutes
        }

        guard NonNegotiableDefinition.isValidEstimatedDuration(value) else { return nil }
        return value
    }

    private func canEdit(_ field: ProtocolField) -> Bool {
        editor.editableFields.contains(field)
    }

    @ViewBuilder
    private func disabledCaption(for field: ProtocolField) -> some View {
        if canEdit(field) == false {
            caption(
                PolicyReason.cannotEditFieldDuringLock(
                    field: field,
                    daysRemaining: editor.lockDaysRemaining,
                    endsOn: editor.lockEndsOn
                ).copy().message
            )
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.secondary)
    }
}

private enum PlanDropPayload {
    static let queuePrefix = "queue:"
    static let allocationPrefix = "allocation:"

    static func queuePayload(for id: UUID) -> String {
        "\(queuePrefix)\(id.uuidString)"
    }

    static func allocationPayload(for id: UUID) -> String {
        "\(allocationPrefix)\(id.uuidString)"
    }

    static func protocolId(from payload: String) -> UUID? {
        guard payload.hasPrefix(queuePrefix) else { return nil }
        let value = String(payload.dropFirst(queuePrefix.count))
        return UUID(uuidString: value)
    }

    static func allocationId(from payload: String) -> UUID? {
        guard payload.hasPrefix(allocationPrefix) else { return nil }
        let value = String(payload.dropFirst(allocationPrefix.count))
        return UUID(uuidString: value)
    }
}
