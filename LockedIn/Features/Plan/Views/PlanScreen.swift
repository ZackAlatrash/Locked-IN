import SwiftUI

private enum PlanBoardMode {
    case focusToday
    case expandedWeek
}

struct PlanScreen: View {
    @Binding var selectedTab: MainTab

    @EnvironmentObject private var commitmentStore: CommitmentSystemStore
    @EnvironmentObject private var planStore: PlanStore
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel = PlanViewModel()
    @State private var showProfile = false
    @State private var boardMode: PlanBoardMode = .focusToday
    @State private var activeDragPayload: String?
    @State private var targetedSlotId: String?
    @State private var hasInteractedWithBoardScroll = false
    @State private var toast: PlanToast?
    @State private var pendingUndo: PlanUndoAction?

    private var isDarkMode: Bool { colorScheme == .dark }
    private var navItemColor: Color { isDarkMode ? Theme.Colors.textSecondary : Color(hex: "111827") }
    private var accentColor: Color { isDarkMode ? Color(hex: "#00F2FF") : Color(hex: "#0EA5E9") }

    var body: some View {
        ZStack {
            pageBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    planBoardSection
                    queueSection
                    todayAtGlanceSection
                    distributionStatus
                    legend
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    selectedTab = .logs
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))

                        Circle()
                            .fill(accentColor)
                            .frame(width: 7, height: 7)
                            .offset(x: 5, y: -3)
                    }
                    .foregroundColor(navItemColor)
                }
                .accessibilityLabel("Open logs")

                Button {
                    showProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(navItemColor)
                }
                .accessibilityLabel("Open profile")
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
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            boardMode = .focusToday
            hasInteractedWithBoardScroll = false
            viewModel.bind(planStore: planStore, commitmentStore: commitmentStore)
        }
        .overlay(alignment: .top) {
            if let warning = viewModel.warningMessage {
                Text(warning)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "111827"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isDarkMode ? Color.red.opacity(0.22) : Color.yellow.opacity(0.26))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(isDarkMode ? Color.red.opacity(0.5) : Color.orange.opacity(0.42), lineWidth: 1)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                planToastView(toast)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 22)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

private extension PlanScreen {
    var planBoardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            planBoardHeader
            if boardMode == .focusToday && hasInteractedWithBoardScroll == false {
                boardScrollHint
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            weekPillars
        }
    }

    var planBoardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STRUCTURAL PLAN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(isDarkMode ? Color(hex: "00D9FF") : Color(hex: "334155"))
                Text(viewModel.weekSubtitle)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(textMuted)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    boardMode = boardMode == .focusToday ? .expandedWeek : .focusToday
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: boardMode == .expandedWeek ? "rectangle.split.3x1.fill" : "rectangle.split.3x1")
                        .font(.system(size: 12, weight: .bold))
                    Text(boardMode == .expandedWeek ? "FOCUS TODAY" : "EXPAND WEEK")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .foregroundColor(textMain)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.85))
                )
                .overlay(
                    Capsule()
                        .stroke(isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    var queueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("QUEUE : PROTOCOLS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.3)
                    .foregroundColor(textMuted)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "FACC15"))
                        .frame(width: 7, height: 7)
                    Text("\(viewModel.queueItems.reduce(0) { $0 + $1.remainingCount }) AVAILABLE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(textMain.opacity(0.78))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
            }

            Text("Drag a protocol onto an open slot, or tap a protocol then tap a slot.")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(textSubtle)

            if viewModel.queueItems.isEmpty {
                Text(viewModel.hasTrackableProtocols ? "All scheduled" : "No active protocols")
                    .font(.system(size: 12, weight: .semibold))
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

        let card = Button {
            viewModel.selectProtocol(id: item.protocolId)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: queueIcon(for: item.tone))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tone)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(item.isDisabled ? textMuted : textMain)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(item.isDisabled ? "SUSPENDED" : "\(item.remainingCount) REMAINING")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(item.isDisabled ? textMuted : tone)
                        Text(item.durationLabel)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(textMuted)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(width: 228, alignment: .leading)
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
        }
        .buttonStyle(.plain)

        if item.isDisabled {
            card
        } else {
            card.draggable(payload) {
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
    }

    var todayAtGlanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY AT A GLANCE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(textSubtle)
            Text(value)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(toneColor(for: tone))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var weekPillars: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: boardMode == .expandedWeek ? 12 : 8) {
                timeAxisColumn

                ForEach(viewModel.currentWeekDays) { day in
                    dayColumn(day)
                        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: boardMode)
                }
            }
            .padding(.vertical, 4)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 6).onChanged { _ in
                guard hasInteractedWithBoardScroll == false else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    hasInteractedWithBoardScroll = true
                }
            }
        )
    }

    var timeAxisColumn: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 34)
            ForEach(PlanSlot.allCases) { slot in
                Text(slot.title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(textSubtle)
                    .frame(width: 20, height: slotHeight(isCompact: false))
            }
        }
    }

    func dayColumn(_ day: PlanDayModel) -> some View {
        let isCompact = boardMode == .focusToday && day.isToday == false
        let width = dayWidth(for: day, isCompact: isCompact)

        return VStack(spacing: 6) {
            VStack(spacing: 1) {
                Text(day.weekdayLabel)
                    .font(.system(size: day.isToday ? 12 : 10, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(day.isToday ? todayAccent : textSubtle)
                if day.isCompactEligible == false || boardMode == .expandedWeek {
                    Text(day.dayNumberLabel)
                        .font(.system(size: day.isToday ? 13 : 10, weight: .black, design: .monospaced))
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
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(isDarkMode ? Color(hex: "020617") : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(day.isToday ? todayAccent : Color.gray))
            }
        }
    }

    func slotCard(day: PlanDayModel, slot: PlanSlotModel, isCompact: Bool) -> some View {
        let dropFeedback = dropFeedback(for: day, slot: slot)

        return Group {
            if isCompact {
                compactSlotCard(day: day, slot: slot, feedback: dropFeedback)
            } else {
                expandedSlotCard(day: day, slot: slot, feedback: dropFeedback)
            }
        }
        .frame(height: slotHeight(isCompact: isCompact))
        .overlay(alignment: .topLeading) {
            if let message = dropFeedback.message {
                Text(message)
                    .font(.system(size: 7, weight: .black, design: .monospaced))
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
                                .font(.system(size: isCompact ? 8 : 9, weight: .black))
                                .lineLimit(1)
                            Text(preview.durationLabel)
                                .font(.system(size: isCompact ? 7 : 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(dropFeedback.isAllowed ? toneColor(for: preview.tone) : Color(hex: "EF4444"))
                    }
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

    func compactSlotCard(day: PlanDayModel, slot: PlanSlotModel, feedback: PlanSlotDropFeedback) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.02))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    slotStrokeColor(slot: slot, feedback: feedback, inCompact: true),
                    style: StrokeStyle(lineWidth: feedback.isTargeted ? 1.4 : 1, dash: slot.busyMinutes > 0 ? [4, 3] : [5, 4])
                )

            if let first = slot.allocations.first {
                Button {
                    viewModel.editAllocation(allocationId: first.id)
                } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(allocationFill(for: first.tone))
                        .overlay(
                            Image(systemName: first.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(allocationTextColor)
                        )
                        .overlay(alignment: .topTrailing) {
                            if slot.allocations.count > 1 {
                                Text("\(slot.allocations.count)")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(allocationTextColor)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.black.opacity(0.2)))
                                    .padding(5)
                            }
                        }
                        .padding(6)
                }
                .buttonStyle(.plain)
                .draggable(PlanDropPayload.allocationPayload(for: first.id)) {
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
            } else if slot.freeMinutes > 0 {
                Button {
                    if let mutation = viewModel.placeSelectedProtocol(day: day.date, slot: slot.slot) {
                        showToast(for: mutation)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(feedback.isAllowed ? todayAccent.opacity(0.75) : todayAccent.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .shadow(
            color: feedback.isTargeted && feedback.isAllowed ? todayAccent.opacity(isDarkMode ? 0.35 : 0.16) : .clear,
            radius: feedback.isTargeted ? 8 : 0,
            x: 0,
            y: 0
        )
    }

    func expandedSlotCard(day: PlanDayModel, slot: PlanSlotModel, feedback: PlanSlotDropFeedback) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(slot.slot.title)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(textSubtle)
                Spacer()
                Text(slot.availableLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(slot.freeMinutes > 0 ? textMuted : Color(hex: "F59E0B"))
            }

            if slot.busyMinutes > 0 {
                Text("BUSY \(minutesString(slot.busyMinutes))")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
            }

            ForEach(slot.allocations) { allocation in
                allocationChip(allocation)
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
            }

            if slot.freeMinutes > 0 {
                Button {
                    if let mutation = viewModel.placeSelectedProtocol(day: day.date, slot: slot.slot) {
                        showToast(for: mutation)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(feedback.message == nil ? "DROP OR TAP TO PLACE" : "UNAVAILABLE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(
                        feedback.message == nil
                            ? (isDarkMode ? Color(hex: "00F2FF").opacity(0.7) : Color(hex: "0EA5E9").opacity(0.8))
                            : Color(hex: "EF4444").opacity(0.75)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
            } else if slot.allocations.isEmpty {
                Text("FULL")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
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

    func allocationChip(_ allocation: PlanAllocationDisplay) -> some View {
        Button {
            viewModel.editAllocation(allocationId: allocation.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: allocation.icon)
                    .font(.system(size: 10, weight: .bold))
                VStack(alignment: .leading, spacing: 3) {
                    Text(allocation.title.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .lineLimit(1)
                    Text(allocation.durationLabel)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                }
                Spacer(minLength: 0)
            }
            .foregroundColor(allocationTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(allocationBackground(tone: allocation.tone))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(toneColor(for: allocation.tone).opacity(isDarkMode ? 0.6 : 0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var distributionStatus: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.structureStatus.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(structureColor)
                Text(viewModel.structureStatus.title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.1)
                    .foregroundColor(textMain.opacity(0.85))
            }
            Text(viewModel.structureMessage)
                .font(.system(size: 9, weight: .semibold))
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
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    var boardScrollHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 10, weight: .bold))
            Text("Swipe left or right to see all days")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(0.5)
        }
        .foregroundColor(textMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.86)))
        .overlay(
            Capsule()
                .stroke(isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    func queueDragPreview(item: PlanQueueItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: queueIcon(for: item.tone))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(toneColor(for: item.tone))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.uppercased())
                    .font(.system(size: 9, weight: .black))
                Text(item.durationLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundColor(textMain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(glassCard(cornerRadius: 12))
    }

    func allocationDragPreview(allocation: PlanAllocationDisplay) -> some View {
        HStack(spacing: 8) {
            Image(systemName: allocation.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(toneColor(for: allocation.tone))
            VStack(alignment: .leading, spacing: 2) {
                Text(allocation.title.uppercased())
                    .font(.system(size: 9, weight: .black))
                Text(allocation.durationLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
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
                return false
            }
            showToast(for: mutation)
            return true
        }

        if let allocationId = PlanDropPayload.allocationId(from: payload) {
            guard let mutation = viewModel.moveAllocation(allocationId: allocationId, to: day, slot: slot) else {
                return false
            }
            showToast(for: mutation)
            return true
        }

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
                withAnimation(.easeOut(duration: 0.2)) {
                    toast = nil
                    pendingUndo = nil
                }
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

        withAnimation(.easeOut(duration: 0.2)) {
            toast = nil
            self.pendingUndo = nil
        }
    }

    func planToastView(_ toast: PlanToast) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(toneColor(for: .cyan))

            Text(toast.message)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textMain)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button(toast.undoLabel) {
                applyUndo()
            }
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundColor(toneColor(for: .cyan))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(glassCard(cornerRadius: 14))
    }

    func dayWidth(for day: PlanDayModel, isCompact: Bool) -> CGFloat {
        if isCompact { return 80 }
        if boardMode == .expandedWeek { return 194 }
        if day.isToday { return 198 }
        return 80
    }

    func slotHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 150 : 188
    }

    func queueIcon(for tone: PlanTone) -> String {
        switch tone {
        case .cyan: return "bolt.fill"
        case .indigo: return "brain.head.profile"
        case .purple: return "aqi.medium"
        case .amber: return "flame.fill"
        case .blue: return "drop.fill"
        }
    }

    func allocationFill(for tone: PlanTone) -> Color {
        toneColor(for: tone).opacity(isDarkMode ? 0.22 : 0.18)
    }

    func minutesString(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

private extension PlanDayModel {
    var isCompactEligible: Bool { isToday == false }
}

private extension PlanScreen {
    @ViewBuilder
    var pageBackground: some View {
        if isDarkMode {
            LinearGradient(
                colors: [Color(hex: "1A243D"), Color(hex: "020617")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } else {
            ZStack {
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
            .ignoresSafeArea()
        }
    }

    var textMain: Color { isDarkMode ? .white : Color(hex: "0B1220") }
    var textMuted: Color { isDarkMode ? Color.white.opacity(0.52) : Color(hex: "6B7280") }
    var textSubtle: Color { isDarkMode ? Color.white.opacity(0.34) : Color(hex: "9CA3AF") }
    var todayAccent: Color { isDarkMode ? Color(hex: "00F2FF") : Color(hex: "0F172A") }

    var structureColor: Color {
        switch viewModel.structureStatus {
        case .structural: return isDarkMode ? Color(hex: "00F2FF") : Color(hex: "0EA5E9")
        case .fragile: return Color(hex: "F59E0B")
        case .unstructured: return Color(hex: "EF4444")
        }
    }

    var columnBackground: Color {
        isDarkMode ? Color(hex: "0F172A").opacity(0.35) : Color.white.opacity(0.52)
    }

    var columnStroke: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    var todayColumnBackground: Color {
        isDarkMode ? Color(hex: "001A2A").opacity(0.56) : Color.white.opacity(0.9)
    }

    var availableBackground: Color {
        isDarkMode ? Color.white.opacity(0.02) : Color.black.opacity(0.015)
    }

    func glassCard(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isDarkMode ? Color(hex: "0F172A").opacity(0.4) : Color.white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
    }

    func toneColor(for tone: PlanTone) -> Color {
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

private struct PlanToast {
    let message: String
    let undoLabel: String
}

private enum PlanUndoAction {
    case remove(allocationId: UUID)
    case move(allocationId: UUID, day: Date, slot: PlanSlot)
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
                        .font(.system(size: 16, weight: .bold))
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
                        onMove(selectedDay, selectedSlot)
                        dismiss()
                    }
                }

                Section {
                    Button("Remove Allocation", role: .destructive) {
                        onRemove()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
