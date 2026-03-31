import SwiftUI
import Combine

private struct CockpitDetailsSelection: Identifiable {
    let id: UUID
}

struct ProfileToolbarButton: View {
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(foregroundColor)
                .frame(width: 44, height: 44, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile") // [VERIFY]
    }
}

@MainActor
struct CockpitView: View {
    @Binding var selectedTab: MainTab
    let onRequestDailyCheckIn: () -> Void

    @EnvironmentObject private var store: CommitmentSystemStore
    @EnvironmentObject private var planStore: PlanStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appClock: AppClock
    @EnvironmentObject private var devRuntime: DevRuntimeState
    @StateObject private var viewModel = CockpitViewModel()
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue

    @State private var activeRoute: CockpitRoute?

    @State private var showCreateNonNegotiable = false
    @State private var detailsSelection: CockpitDetailsSelection?

    @State private var actionErrorMessage: String?
    @State private var completionToastMessage: String?

    init(
        selectedTab: Binding<MainTab> = .constant(.cockpit),
        onRequestDailyCheckIn: @escaping () -> Void = {}
    ) {
        _selectedTab = selectedTab
        self.onRequestDailyCheckIn = onRequestDailyCheckIn
    }

    var body: some View {
        ZStack {
            modernCockpitContent
        }
        .navigationTitle("Cockpit")
        .navigationBarTitleDisplayMode(.large)
        .tint(navItemColor)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ProfileToolbarButton(foregroundColor: navItemColor) {
                    perform(.openProfile)
                }
            }
        }
        .navigationDestination(item: $activeRoute) { route in
            routeDestination(route)
        }
        .onAppear {
            refreshFromStore(referenceDate: appClock.now)
        }
        .onReceive(store.$system) { _ in
            refreshFromStore(referenceDate: appClock.now)
        }
        .onChange(of: appClock.simulatedNow) { _ in
            refreshFromStore(referenceDate: appClock.now)
        }
        .sheet(isPresented: $showCreateNonNegotiable) {
            NavigationStack {
                CreateNonNegotiableView(
                    accentColorOverride: accentColor,
                    onSuccess: {
                        showCreateNonNegotiable = false
                    },
                    onBack: {
                        showCreateNonNegotiable = false
                    }
                )
                .environmentObject(store)
            }
        }
        .sheet(item: $detailsSelection) { selection in
            if let nn = store.system.nonNegotiables.first(where: { $0.id == selection.id }) {
                CockpitNonNegotiableDetailsSheet(
                    nonNegotiable: nn,
                    onAction: perform
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            } else {
                VStack {
                    Text("Protocol not available")
                        .font(.headline)
                    Button("Close") {
                        detailsSelection = nil
                    }
                }
                .padding(24)
            }
        }
        .alert(
            "Action Failed",
            isPresented: Binding(
                get: { actionErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        actionErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(actionErrorMessage ?? "Unknown error")
            }
        )
        .overlay(alignment: .top) {
            if let completionToastMessage {
                Text(completionToastMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(cockpitStyle == .dark ? .white : Color(hex: "0F172A"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(cockpitStyle == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(cockpitStyle == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.14), lineWidth: 1)
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private extension CockpitView {
    var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark
    }

    var cockpitStyle: CockpitModernStyle {
        appAppearanceMode.cockpitStyle
    }

    var isRecoveryThemeActive: Bool {
        viewModel.uiState.modeText.uppercased() == "RECOVERY"
    }

    var navItemColor: Color {
        cockpitStyle == .dark ? Theme.Colors.textSecondary : Color(hex: "111827")
    }

    var navAvatarBackground: Color {
        cockpitStyle == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    var navAvatarStroke: Color {
        cockpitStyle == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    var modernCockpitContent: some View {
        CockpitModernView(
            style: cockpitStyle,
            accentColor: accentColor,
            weeklyAccentColor: weeklyAccentColor,
            streakAccentColor: streakAccentColor,
            reliabilityScore: viewModel.uiState.reliabilityScore,
            modeText: viewModel.uiState.modeText,
            recoveryProgressText: viewModel.uiState.recoveryProgressText,
            capacityStatusText: viewModel.uiState.capacityStatusText,
            activeCapacityCountText: viewModel.uiState.capacityCountText,
            pendingCount: max(0, cards.filter { $0.badge == .due || $0.badge == .pending }.count),
            streakDays: viewModel.uiState.currentStreakDays,
            protocolLoad: min(
                max(
                    Double(viewModel.uiState.activeCount) /
                    Double(max(viewModel.uiState.allowedCapacity, 1)),
                    0
                ),
                1
            ),
            todayCompleted: viewModel.uiState.todayCompleted,
            todayCompletionCount: todayCompletionCount,
            weeklyCompletionCount: weeklyCompletionCount,
            weeklyTargetCount: weeklyTargetCount,
            weeklyCompletionByDay: weeklyCompletionByDay,
            capacityProtocols: viewModel.uiState.todayTasks,
            upcomingProtocols: viewModel.uiState.upcomingTasks,
            showEmbeddedHeader: false,
            onWeeklyActivityTap: { perform(.openWeeklyActivity) },
            onStreakTap: { perform(.openStreak) },
            onCapacityTap: { perform(.openCapacity) },
            onCreateTap: { perform(.openCreate) },
            onCheckInTap: {
                Haptics.selection()
                onRequestDailyCheckIn()
            },
            onProtocolComplete: { nnId in
                perform(.complete(nnId: nnId))
            },
            onProtocolUndo: { nnId in
                perform(.undo(nnId: nnId))
            },
            onProtocolTap: { nnId in
                perform(.openDetails(nnId: nnId))
            }
        )
    }

    var cards: [CockpitNonNegotiableCardModel] {
        viewModel.uiState.nonNegotiables
    }

    var todayCompletionCount: Int {
        store.countedCompletionLog.filter {
            DateRules.isoCalendar.isDate($0.date, inSameDayAs: appClock.now)
        }.count
    }

    var weeklyCompletionCount: Int {
        let weekId = DateRules.weekID(for: appClock.now)
        return store.countedCompletionLog.filter { $0.weekId == weekId }.count
    }

    var weeklyTargetCount: Int {
        let tracked = store.system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery || $0.state == .suspended
        }
        return tracked.reduce(0) { partial, nn in
            partial + nn.definition.frequencyPerWeek
        }
    }

    var weeklyCompletionByDay: [Int] {
        let calendar = DateRules.isoCalendar
        let weekStart = DateRules.weekInterval(containing: appClock.now, calendar: calendar).start
        return (0..<7).map { dayOffset in
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            return store.countedCompletionLog.filter {
                calendar.isDate($0.date, inSameDayAs: dayStart)
            }.count
        }
    }

    var accentColor: Color {
        if isRecoveryThemeActive {
            return cockpitStyle == .dark ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
        }
        return appAppearanceMode.primaryAccentColor
    }

    var weeklyAccentColor: Color {
        if isRecoveryThemeActive {
            return cockpitStyle == .dark ? Color(hex: "#EF4444") : Color(hex: "#DC2626")
        }
        return cockpitStyle == .dark ? Color(hex: "#38BDF8") : Color(hex: "#0C7AA6")
    }

    var streakAccentColor: Color {
        if isRecoveryThemeActive {
            return cockpitStyle == .dark ? Color(hex: "#FB7185") : Color(hex: "#991B1B")
        }
        return cockpitStyle == .dark ? Color(hex: "#F59E0B") : Color(hex: "#B45309")
    }

    @ViewBuilder
    func routeDestination(_ route: CockpitRoute) -> some View {
        switch route {
        case .weeklyActivity:
            WeeklyActivityDetailView(
                weeklyCompletionByDay: weeklyCompletionByDay,
                weeklyCompletionCount: weeklyCompletionCount,
                weeklyTargetCount: weeklyTargetCount,
                todayCompletionCount: todayCompletionCount,
                accentColor: accentColor,
                onOpenLogs: { perform(.openLogs) }
            )
        case .streak:
            StreakDetailView(
                currentStreakDays: viewModel.uiState.currentStreakDays,
                todayCompleted: viewModel.uiState.todayCompleted,
                lastCompletionDate: store.lastCompletionDate,
                firstTask: viewModel.uiState.todayTasks.first,
                accentColor: accentColor,
                onMarkTodayDone: { nnId in
                    perform(.complete(nnId: nnId))
                },
                onOpenLogs: { perform(.openLogs) }
            )
        case .capacity:
            CapacityDetailView(
                system: store.system,
                accentColor: accentColor,
                onSelectProtocol: { nnId in
                    perform(.openDetails(nnId: nnId))
                },
                onOpenLogs: { perform(.openLogs) }
            )
        case .profile:
            ProfilePlaceholderView()
        }
    }

    func refreshFromStore(referenceDate: Date) {
        viewModel.refresh(
            system: store.system,
            isStable: store.isSystemStable,
            planSnapshot: planStore.currentWeekSnapshot(),
            reliabilityOverride: devRuntime.reliabilityOverride,
            currentStreakDays: store.currentStreakDays(referenceDate: referenceDate),
            todayCompleted: store.todayCompleted(referenceDate: referenceDate),
            referenceDate: referenceDate
        )
    }

    func perform(_ action: CockpitAction) {
        switch action {
        case .complete(let nnId):
            do {
                guard let protocolModel = store.system.nonNegotiables.first(where: { $0.id == nnId }) else {
                    actionErrorMessage = "This protocol is no longer available."
                    return
                }
                let outcome = try store.recordCompletionDetailed(for: nnId, at: appClock.now)
                let reconciliation = planStore.reconcileAfterCompletion(
                    protocolId: nnId,
                    mode: protocolModel.definition.mode,
                    completionDate: outcome.date,
                    completionKind: outcome.kind
                )
                store.runDailyIntegrityTick(referenceDate: appClock.now)
                if outcome.kind == .extra {
                    if protocolModel.definition.mode == .session {
                        showCompletionToast("Weekly target already met. Logged as EXTRA.")
                    } else {
                        showCompletionToast("Logged as EXTRA.")
                    }
                } else if case .released(let released) = reconciliation {
                    showCompletionToast(
                        releasedToastMessage(
                            protocolTitle: protocolModel.definition.title,
                            completionDate: outcome.date,
                            releasedDay: released.day,
                            slot: released.slot
                        )
                    )
                }
                Haptics.success()
            } catch {
                Haptics.warning()
                actionErrorMessage = actionMessage(for: error)
            }

        case .undo(let nnId):
            do {
                guard let protocolModel = store.system.nonNegotiables.first(where: { $0.id == nnId }) else {
                    actionErrorMessage = "This protocol is no longer available."
                    return
                }
                let removed = try store.undoLatestCompletionToday(for: nnId, at: appClock.now)
                store.runDailyIntegrityTick(referenceDate: appClock.now)
                if removed.kind == .extra {
                    showCompletionToast("Removed EXTRA for \(protocolModel.definition.title).")
                } else {
                    showCompletionToast("Undid completion for \(protocolModel.definition.title).")
                }
                Haptics.selection()
            } catch {
                Haptics.warning()
                actionErrorMessage = actionMessage(for: error)
            }

        case .openDetails(let nnId):
            Haptics.selection()
            detailsSelection = CockpitDetailsSelection(id: nnId)

        case .edit(let nnId):
            Haptics.selection()
            detailsSelection = nil
            router.openPlanEditor(protocolId: nnId)

        case .openCreate:
            Haptics.selection()
            showCreateNonNegotiable = true

        case .openLogs:
            Haptics.selection()
            selectedTab = .logs

        case .openPlan:
            Haptics.selection()
            selectedTab = .plan

        case .openWeeklyActivity:
            Haptics.selection()
            activeRoute = .weeklyActivity

        case .openStreak:
            Haptics.selection()
            activeRoute = .streak

        case .openCapacity:
            Haptics.selection()
            activeRoute = .capacity

        case .openProfile:
            Haptics.selection()
            activeRoute = .profile

        case .retire(let nnId):
            do {
                store.runDailyIntegrityTick(referenceDate: appClock.now)
                try store.retireNonNegotiable(id: nnId, referenceDate: appClock.now)
                Haptics.success()
                detailsSelection = nil
            } catch {
                Haptics.warning()
                actionErrorMessage = actionMessage(for: error)
            }
        }
    }

    func actionMessage(for error: Error) -> String {
        if let copy = store.policyCopy(for: error) {
            return copy.message
        }

        if let systemError = error as? CommitmentSystemError {
            switch systemError {
            case .capacityExceeded:
                return "Capacity reached. You cannot add another protocol right now."
            case .nonNegotiableNotFound:
                return "This protocol is no longer available."
            case .cannotRemoveDuringLock:
                return "Locked protocol. Retirement is available after lock end."
            case .systemUnstable:
                return "System is in recovery. Complete active protocols to stabilize."
            }
        }

        if let engineError = error as? NonNegotiableEngineError {
            switch engineError {
            case .invalidDefinition:
                return "Invalid protocol definition."
            case .outsideLockPeriod:
                return "Completion is available only during the lock period."
            case .alreadyRetiredOrCompleted:
                return "This protocol is already closed."
            case .alreadyCompletedToday:
                return "Already completed today."
            case .extraAlreadyLoggedToday:
                return "EXTRA already logged today for this protocol."
            }
        }

        return error.localizedDescription
    }

    func showCompletionToast(_ message: String) {
        completionToastMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            if completionToastMessage == message {
                completionToastMessage = nil
            }
        }
    }

    func releasedDaySlotLabel(day: Date, slot: PlanSlot) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return "\(formatter.string(from: day).uppercased()) \(slot.title)"
    }

    func releasedToastMessage(protocolTitle: String, completionDate: Date, releasedDay: Date, slot: PlanSlot) -> String {
        let completionDay = DateRules.startOfDay(completionDate)
        let tomorrow = DateRules.addingDays(1, to: completionDay)
        let releasedDayStart = DateRules.startOfDay(releasedDay)
        if releasedDayStart == tomorrow {
            return "\(protocolTitle) wasn't scheduled today. Tomorrow's \(slot.title) session was removed."
        }
        return "\(protocolTitle) wasn't scheduled today. \(releasedDaySlotLabel(day: releasedDayStart, slot: slot)) was removed."
    }
}

private struct CockpitNonNegotiableDetailsSheet: View {
    let nonNegotiable: NonNegotiable
    let onAction: (CockpitAction) -> Void
    @EnvironmentObject private var store: CommitmentSystemStore
    @EnvironmentObject private var appClock: AppClock
    @Environment(\.colorScheme) private var colorScheme

    private var now: Date { appClock.now }
    private var calendar: Calendar { DateRules.isoCalendar }
    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    private var cardBackground: Color { isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }
    private var textPrimary: Color { isDarkMode ? Color.white : Color(hex: "101827") }
    private var textSecondary: Color { isDarkMode ? Color.white.opacity(0.72) : Color(hex: "6B7280") }
    private var textMuted: Color { isDarkMode ? Color.white.opacity(0.48) : Color(hex: "9CA3AF") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text(nonNegotiable.definition.title)
                    .font(.title2.weight(.heavy))
                    .foregroundColor(textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    detailRow("Mode", value: nonNegotiable.definition.mode == .daily ? "Daily" : "Session")
                    detailRow("Frequency", value: "\(nonNegotiable.definition.frequencyPerWeek) / week")
                    detailRow("State", value: stateLabel(nonNegotiable.state))
                    detailRow("Lock Remaining", value: lockDaysRemainingText)
                    detailRow("This Week", value: "\(thisWeekCount) / \(nonNegotiable.definition.frequencyPerWeek)")
                    detailRow("Remaining", value: remainingThisWeekText)
                    if extraLoggedToday {
                        detailRow("Today", value: "Extra logged")
                    }
                    if nonNegotiable.state == .suspended {
                        detailRow("Status", value: "Suspended (system stabilizing)")
                    }
                    if nonNegotiable.state == .recovery {
                        detailRow("Recovery", value: "Recovery rules active")
                    }
                }
                .padding(14)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                lawSection

                Button {
                    onAction(.complete(nnId: nonNegotiable.id))
                } label: {
                    Text(markDoneTitle)
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(markDoneDisabled)

                if let markDoneDisabledMessage {
                    Text(markDoneDisabledMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    onAction(.edit(nnId: nonNegotiable.id))
                } label: {
                    Text("Edit")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    onAction(.retire(nnId: nonNegotiable.id))
                } label: {
                    Text("Retire")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .disabled(!isLockEnded)

                if !isLockEnded {
                    Text("Locked until \(lockEndDateText) (\(lockDaysRemainingText) left)")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if nonNegotiable.state == .recovery {
                    Text("Must complete at least 1 protocol/day for 7 clean days.")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(textSecondary)
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }
        .background(pageBackground)
    }

    private var lockEndDate: Date {
        DateRules.addingDays(nonNegotiable.lock.totalLockDays, to: DateRules.startOfDay(nonNegotiable.lock.startDate))
    }

    private var isLockEnded: Bool {
        now >= lockEndDate
    }

    private var lockDaysRemainingText: String {
        let remaining = max(0, DateRules.isoCalendar.dateComponents([.day], from: DateRules.startOfDay(now), to: lockEndDate).day ?? 0)
        return "\(remaining) day\(remaining == 1 ? "" : "s")"
    }

    private var lockEndDateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: lockEndDate)
    }

    private var completedToday: Bool {
        nonNegotiable.completions.contains {
            $0.kind == .counted && calendar.isDate($0.date, inSameDayAs: now)
        }
    }

    private var extraLoggedToday: Bool {
        nonNegotiable.completions.contains {
            $0.kind == .extra && calendar.isDate($0.date, inSameDayAs: now)
        }
    }

    private var markDoneDisabled: Bool {
        if nonNegotiable.state == .suspended || nonNegotiable.state == .completed || nonNegotiable.state == .retired {
            return true
        }
        if extraLoggedToday {
            return true
        }
        if completedToday {
            return true
        }
        return false
    }

    private var markDoneTitle: String {
        if extraLoggedToday {
            return "Extra Logged"
        }
        if completedToday {
            return "Done"
        }
        if nonNegotiable.definition.mode == .session && thisWeekCount >= nonNegotiable.definition.frequencyPerWeek {
            return "Log Extra"
        }
        return "Mark Done"
    }

    private var markDoneDisabledMessage: String? {
        if extraLoggedToday {
            return PolicyReason.extraAlreadyLoggedToday.copy().message
        }
        if completedToday {
            return PolicyReason.alreadyCompletedToday.copy().message
        }
        switch nonNegotiable.state {
        case .suspended:
            return PolicyReason.protocolSuspended.copy().message
        case .completed, .retired:
            return PolicyReason.protocolCompletedOrRetired.copy().message
        default:
            return nil
        }
    }

    private var thisWeekCount: Int {
        let weekId = DateRules.weekID(for: now)
        return nonNegotiable.completions.filter {
            $0.weekId == weekId && $0.kind == .counted
        }.count
    }

    private var remainingThisWeekText: String {
        let remaining = max(nonNegotiable.definition.frequencyPerWeek - thisWeekCount, 0)
        if nonNegotiable.definition.mode == .daily {
            return "\(remaining) day\(remaining == 1 ? "" : "s")"
        }
        return "\(remaining) session\(remaining == 1 ? "" : "s")"
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(textMuted)
            Spacer()
            Text(value)
                .font(.body.weight(.bold))
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stateLabel(_ state: NonNegotiableState) -> String {
        switch state {
        case .draft:
            return "Draft"
        case .active:
            return "Active"
        case .recovery:
            return "Recovery"
        case .suspended:
            return "Suspended"
        case .completed:
            return "Completed"
        case .retired:
            return "Retired"
        }
    }

    @ViewBuilder
    private var lawSection: some View {
        let reasons = store.lawReasons(for: nonNegotiable.id, referenceDate: now)
        if reasons.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                Text("LAW")
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                    .foregroundColor(textMuted)

                ForEach(Array(reasons.enumerated()), id: \.offset) { entry in
                    let reason = entry.element
                    let copy = reason.copy()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(copy.title.uppercased())
                            .font(.caption.weight(.black))
                            .foregroundColor(textPrimary)
                        Text(copy.message)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let hint = copy.hint {
                            Text(hint)
                                .font(.caption.weight(.medium))
                                .foregroundColor(textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView(selectedTab: .constant(.cockpit))
            .environmentObject(
                CommitmentSystemStore(
                    repository: InMemoryCommitmentSystemRepository(),
                    systemEngine: CommitmentSystemEngine(nonNegotiableEngine: NonNegotiableEngine()),
                    nonNegotiableEngine: NonNegotiableEngine()
                )
            )
            .preferredColorScheme(.dark)
    }
}
