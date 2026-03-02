import SwiftUI

private struct CockpitDetailsSelection: Identifiable {
    let id: UUID
}

@MainActor
struct CockpitView: View {
    @Binding var selectedTab: MainTab

    @EnvironmentObject private var store: CommitmentSystemStore
    @StateObject private var viewModel = CockpitViewModel()
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue

    @State private var activeRoute: CockpitRoute?

    @State private var showCreateNonNegotiable = false
    @State private var detailsSelection: CockpitDetailsSelection?

    @State private var actionErrorMessage: String?

    init(selectedTab: Binding<MainTab> = .constant(.cockpit)) {
        _selectedTab = selectedTab
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
                Button {
                    perform(.openLogs)
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
                    perform(.openProfile)
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(navItemColor)
                }
                .accessibilityLabel("Open profile")

                Button {
                    perform(.openCreate)
                } label: {
                    Circle()
                        .fill(navAvatarBackground)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("+")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(navItemColor)
                        )
                        .overlay(Circle().stroke(navAvatarStroke, lineWidth: 1))
                }
                .accessibilityLabel("Create non-negotiable")
            }
        }
        .navigationDestination(item: $activeRoute) { route in
            routeDestination(route)
        }
        .onAppear {
            refreshFromStore()
        }
        .onReceive(store.$system) { _ in
            refreshFromStore()
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
    }
}

private extension CockpitView {
    var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .dark
    }

    var cockpitStyle: CockpitModernStyle {
        appAppearanceMode.cockpitStyle
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
            showEmbeddedHeader: false,
            onWeeklyActivityTap: { perform(.openWeeklyActivity) },
            onStreakTap: { perform(.openStreak) },
            onCapacityTap: { perform(.openCapacity) },
            onProtocolComplete: { nnId in
                perform(.complete(nnId: nnId))
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
        store.completionLog.filter { DateRules.isoCalendar.isDateInToday($0.date) }.count
    }

    var weeklyCompletionCount: Int {
        let weekId = DateRules.weekID(for: Date())
        return store.completionLog.filter { $0.weekId == weekId }.count
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
        let weekStart = DateRules.weekInterval(containing: Date(), calendar: calendar).start
        return (0..<7).map { dayOffset in
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            return store.completionLog.filter {
                calendar.isDate($0.date, inSameDayAs: dayStart)
            }.count
        }
    }

    var accentColor: Color {
        appAppearanceMode.primaryAccentColor
    }

    var weeklyAccentColor: Color {
        cockpitStyle == .dark ? Color(hex: "#38BDF8") : Color(hex: "#0C7AA6")
    }

    var streakAccentColor: Color {
        cockpitStyle == .dark ? Color(hex: "#F59E0B") : Color(hex: "#B45309")
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

    func refreshFromStore() {
        viewModel.refresh(
            system: store.system,
            isStable: store.isSystemStable,
            currentStreakDays: store.currentStreakDays,
            todayCompleted: store.todayCompleted
        )
    }

    func perform(_ action: CockpitAction) {
        switch action {
        case .complete(let nnId):
            do {
                try store.recordCompletion(for: nnId, at: Date())
                store.runDailyIntegrityTick(referenceDate: Date())
            } catch {
                actionErrorMessage = actionMessage(for: error)
            }

        case .openDetails(let nnId):
            detailsSelection = CockpitDetailsSelection(id: nnId)

        case .openCreate:
            showCreateNonNegotiable = true

        case .openLogs:
            selectedTab = .logs

        case .openPlan:
            selectedTab = .plan

        case .openWeeklyActivity:
            activeRoute = .weeklyActivity

        case .openStreak:
            activeRoute = .streak

        case .openCapacity:
            activeRoute = .capacity

        case .openProfile:
            activeRoute = .profile

        case .retire(let nnId):
            do {
                store.runDailyIntegrityTick(referenceDate: Date())
                try store.removeNonNegotiable(id: nnId)
                detailsSelection = nil
            } catch {
                actionErrorMessage = actionMessage(for: error)
            }
        }
    }

    func actionMessage(for error: Error) -> String {
        if let systemError = error as? CommitmentSystemError {
            switch systemError {
            case .capacityExceeded:
                return "Capacity reached. You cannot add another protocol right now."
            case .nonNegotiableNotFound:
                return "This protocol is no longer available."
            case .cannotRemoveDuringLock:
                return "Locked protocol. Retirement is available after lock end."
            case .systemUnstable:
                return "System is unstable. Complete active protocols to stabilize."
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
            }
        }

        return error.localizedDescription
    }
}

private struct CockpitNonNegotiableDetailsSheet: View {
    let nonNegotiable: NonNegotiable
    let onAction: (CockpitAction) -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var now: Date { Date() }
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
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    detailRow("Mode", value: nonNegotiable.definition.mode == .daily ? "Daily" : "Session")
                    detailRow("Frequency", value: "\(nonNegotiable.definition.frequencyPerWeek) / week")
                    detailRow("State", value: stateLabel(nonNegotiable.state))
                    detailRow("Lock Remaining", value: lockDaysRemainingText)
                    detailRow("This Week", value: "\(thisWeekCount) / \(nonNegotiable.definition.frequencyPerWeek)")
                    detailRow("Remaining", value: remainingThisWeekText)
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

                Button {
                    onAction(.complete(nnId: nonNegotiable.id))
                } label: {
                    Text("Mark Done")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(markDoneDisabled)

                if let markDoneDisabledMessage {
                    Text(markDoneDisabledMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                }

                Button(role: .destructive) {
                    onAction(.retire(nnId: nonNegotiable.id))
                } label: {
                    Text("Retire")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .disabled(!isLockEnded)

                if !isLockEnded {
                    Text("Locked until \(lockEndDateText) (\(lockDaysRemainingText) left)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                }

                if nonNegotiable.state == .recovery {
                    Text("Must complete at least 1 protocol/day for 7 clean days.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary)
                        .padding(.top, 4)
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
        nonNegotiable.completions.contains { calendar.isDate($0.date, inSameDayAs: now) }
    }

    private var markDoneDisabled: Bool {
        completedToday || nonNegotiable.state == .suspended || nonNegotiable.state == .completed || nonNegotiable.state == .retired
    }

    private var markDoneDisabledMessage: String? {
        if completedToday { return "Already completed today." }
        switch nonNegotiable.state {
        case .suspended:
            return "Suspended while the system stabilizes."
        case .completed, .retired:
            return "This protocol is closed."
        default:
            return nil
        }
    }

    private var thisWeekCount: Int {
        let weekId = DateRules.weekID(for: now)
        return nonNegotiable.completions.filter { $0.weekId == weekId }.count
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(textPrimary)
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
