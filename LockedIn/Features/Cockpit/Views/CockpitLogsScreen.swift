import SwiftUI

struct CockpitLogsScreen: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject private var store: CommitmentSystemStore
    @EnvironmentObject private var appClock: AppClock
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("phase1MotionSessionID") private var motionSessionID = ""
    @AppStorage("didAnimateLogsPhase1SessionID") private var didAnimateLogsPhase1SessionID = ""
    @State private var showProfile = false
    @State private var hasStartedEntrance = false
    @State private var showIntegritySection = false
    @State private var showPerformanceSection = false
    @State private var showHistorySection = false
    @State private var revealedMatrixCount = 0
    @State private var metricsAnimatedIn = false
    @State private var revealedHistoryCount = 0
    @State private var showAllHistory = false
    @State private var showFiltersSheet = false
    @State private var selectedEventTypes: Set<LogFilterEventType> = []
    @State private var selectedTimeRange: LogTimeRange = .allTime
    @State private var customStartDate = DateRules.isoCalendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var selectedProtocolId: UUID?

    @ScaledMetric(relativeTo: .caption2) private var microDotSize = 6
    @ScaledMetric(relativeTo: .body) private var timelineIconSize = 32
    @ScaledMetric(relativeTo: .caption2) private var progressBarHeight = 8
    @ScaledMetric(relativeTo: .caption2) private var badgeHorizontalPadding = 8
    @ScaledMetric(relativeTo: .caption2) private var badgeVerticalPadding = 4

    private var matrixColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }
    private var effectiveMotionSessionID: String {
        motionSessionID.isEmpty ? "launch-pending" : motionSessionID
    }
    private var didAnimateThisSession: Bool {
        didAnimateLogsPhase1SessionID == effectiveMotionSessionID
    }

    init(selectedTab: Binding<MainTab> = .constant(.logs)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            pageBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    integrityMatrixCard
                        .opacity(showIntegritySection ? 1 : 0)
                        .offset(y: showIntegritySection ? 0 : 14)
                    performanceCards
                        .opacity(showPerformanceSection ? 1 : 0)
                        .offset(y: showPerformanceSection ? 0 : 14)
                    sessionHistory
                        .opacity(showHistorySection ? 1 : 0)
                        .offset(y: showHistorySection ? 0 : 14)
                }
                .padding(.horizontal, 16)
                .padding(.top, Theme.Spacing.navLargeTitleContentTopInset)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Diagnostic Log")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            runEntranceIfNeeded()
        }
        .onChange(of: filteredLogEntries.count) { _, newValue in
            let target = showAllHistory ? newValue : min(historyPreviewCount, newValue)
            revealedHistoryCount = max(target, 0)
        }
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
        .sheet(isPresented: $showFiltersSheet) {
            filterSheet
                .presentationSizing(.fitted)
        }
    }
}

private extension CockpitLogsScreen {
    var header: some View {
        Text("LOCKEDIN: NEURAL INTERFACE")
            .font(.custom("Inter", size: 12, relativeTo: .caption).weight(.semibold))
            .tracking(1.3)
            .foregroundColor(textMuted)
            .padding(.horizontal, 2)
            .padding(.top, 8)
    }

    var integrityMatrixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("28-DAY INTEGRITY MATRIX")
                    .font(.custom("Inter", size: 10, relativeTo: .caption2).weight(.bold))
                    .tracking(1.4)
                    .foregroundColor(textMuted)

                Spacer()

                HStack(spacing: 6) {
                    if isDarkMode {
                        Circle()
                            .fill(cyanAccent)
                            .frame(width: microDotSize, height: microDotSize)
                            .shadow(color: cyanAccent.opacity(0.6), radius: 6, x: 0, y: 0)
                    }
                    Text("\(isRecoveryThemeActive ? "RECOVERY" : "STABLE") • \(adherence)% ADHERENCE")
                        .font(.custom("Inter", size: 10, relativeTo: .caption2).weight(.black))
                        .foregroundColor(adherenceTextColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(adherencePillBackground)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(adherencePillStroke, lineWidth: 1)
                )
            }

            HStack {
                ForEach(weekdayHeaders, id: \.self) { weekday in
                    Text(weekday)
                        .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.bold))
                        .tracking(0.8)
                        .foregroundColor(textSubtle)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: matrixColumns, spacing: 6) {
                ForEach(Array(matrixDays.enumerated()), id: \.element.id) { index, point in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(matrixFill(for: point))
                        .shadow(color: matrixGlow(for: point), radius: 8, x: 0, y: 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(matrixStroke(for: point), lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(todayOutlineColor.opacity(point.isToday ? 1 : 0), lineWidth: point.isToday ? 2 : 0)
                                .padding(point.isToday ? -3 : 0)
                        )
                        .overlay(alignment: .topLeading) {
                            Text(dayNumberText(for: point.day))
                                .font(.custom("Inter", size: 8, relativeTo: .caption2).weight(.bold))
                                .foregroundColor(dayNumberColor(for: point))
                                .padding(.leading, 4)
                                .padding(.top, 3)
                        }
                        .overlay(alignment: .topTrailing) {
                            if let token = matrixToken(for: point) {
                                HStack(spacing: 3) {
                                    if let indicatorColor = cornerIndicatorColor(for: point) {
                                        Circle()
                                            .fill(indicatorColor)
                                            .frame(width: microDotSize, height: microDotSize)
                                    }
                                    Text(token)
                                        .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.bold))
                                        .foregroundColor(dayNumberColor(for: point))
                                }
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                                .background(.thinMaterial, in: Capsule(style: .continuous))
                                .padding(.trailing, 4)
                                .padding(.top, 4)
                            }
                        }
                        .opacity(revealedMatrixCount > index ? 1 : 0)
                        .scaleEffect(revealedMatrixCount > index ? 1 : 0.92)
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            matrixLegend
        }
        .padding(16)
        .background(glassCard(cornerRadius: 26))
    }

    var matrixLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOKEN KEY")
                .font(.custom("Inter", size: 10, relativeTo: .caption2).weight(.black))
                .tracking(0.8)
                .foregroundColor(textMuted)

            HStack(spacing: 10) {
                legendItem(token: "U", label: "Unproductive", description: "required work not completed", color: matrixUnproductiveFill)
                legendItem(token: "V", label: "Violation", description: "violation or inevitable miss", color: matrixViolationFill)
            }
            HStack(spacing: 10) {
                legendItem(token: "C", label: "Completed", description: "counted or no work required", color: matrixHighFill)
                legendItem(token: "E", label: "Extra", description: "extra only", color: isDarkMode ? Color(hex: "FDE047") : Color(hex: "FDE68A"))
            }
        }
        .padding(.top, 6)
    }

    func legendItem(token: String, label: String, description: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: microDotSize, height: microDotSize)
            Text(token)
                .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.black))
                .foregroundColor(textMain)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.thinMaterial, in: Capsule(style: .continuous))
            Text(label)
                .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.bold))
                .foregroundColor(textMuted)
            Text("= \(description)")
                .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.medium))
                .foregroundColor(textSubtle)
        }
    }

    var performanceCards: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Deep Focus",
                value: String(format: "%.1f", deepFocusHours),
                unit: "hrs",
                icon: "bolt.fill",
                iconColor: isDarkMode ? magentaAccent : Color(hex: "60A5FA"),
                bars: deepFocusBars
            )

            metricCard(
                title: "Neural Sync",
                value: "\(neuralSyncPercent)",
                unit: "%",
                icon: "sparkles",
                iconColor: isDarkMode ? cyanAccent : Color(hex: "6366F1"),
                bars: neuralSyncBars
            )
        }
    }

    func metricCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        iconColor: Color,
        bars: [Double]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.custom("Inter", size: 12, relativeTo: .subheadline).weight(.semibold))
                    .foregroundColor(textMain)
                Spacer(minLength: 8)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.custom("Inter", size: isDarkMode ? 34 : 30, relativeTo: .largeTitle).weight(.black))
                    .foregroundColor(textMain)
                Text(unit)
                    .font(.custom("Inter", size: 11, relativeTo: .caption).weight(.semibold))
                    .foregroundColor(textMuted)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, item in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(metricBarColor(index: index, count: bars.count, accent: iconColor))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(8, item * 28 * (metricsAnimatedIn ? 1 : 0.28)))
                        .animation(
                            reduceMotion
                                ? .none
                                : Theme.Animation.content.delay(Double(index) * 0.04),
                            value: metricsAnimatedIn
                        )
                }
            }
            .frame(height: 34)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard(cornerRadius: 20))
    }

    func metricBarColor(index: Int, count: Int, accent: Color) -> Color {
        let isPeak = index == max(0, count - 2)
        if isPeak {
            return accent.opacity(isDarkMode ? 0.95 : 0.82)
        }
        return isDarkMode ? Color.white.opacity(0.08) : accent.opacity(0.25)
    }

    var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text("Session History")
                    .font(.custom("Inter", size: isDarkMode ? 14 : 22, relativeTo: .title3).weight(.bold))
                    .tracking(isDarkMode ? 1.1 : 0)
                    .textCase(isDarkMode ? .uppercase : nil)
                    .foregroundColor(textMain)
                    .padding(.horizontal, 2)
                Spacer(minLength: 0)
                Button {
                    Haptics.selection()
                    showFiltersSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                        if filterSummary.isActive {
                            Circle()
                                .fill(activeAccent)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .font(.custom("Inter", size: 12, relativeTo: .subheadline).weight(.semibold))
                    .foregroundColor(textMain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(glassCard(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open log filters")
            }

            if filterSummary.isActive {
                HStack(spacing: 8) {
                    Text(filterSummary.label)
                        .font(.custom("Inter", size: 12, relativeTo: .subheadline).weight(.semibold))
                        .foregroundColor(textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text("\(filteredLogEntries.count) results")
                        .font(.custom("Inter", size: 11, relativeTo: .caption).weight(.bold))
                        .foregroundColor(textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(glassCard(cornerRadius: 14, muted: true))
            }

            if allLogEntries.isEmpty {
                emptyHistoryState
            } else if filteredLogEntries.isEmpty {
                emptyFilteredHistoryState
            } else {
                ForEach(Array(visibleHistoryEntries.enumerated()), id: \.element.id) { index, entry in
                    if shouldShowDayHeader(for: index) {
                        timelineDayHeader(for: entry.date)
                            .transition(.opacity)
                    }

                    sessionCard(
                        entry,
                        index: index,
                        showsConnector: shouldShowConnector(for: index)
                    )
                        .opacity(revealedHistoryCount > index ? 1 : 0)
                        .offset(y: revealedHistoryCount > index ? 0 : 10)
                }

                if filteredLogEntries.count > historyPreviewCount {
                    Button {
                        Haptics.selection()
                        let expanding = showAllHistory == false
                        withAnimation(Theme.Animation.content) {
                            showAllHistory.toggle()
                            if expanding {
                                revealedHistoryCount = max(revealedHistoryCount, filteredLogEntries.count)
                            } else {
                                revealedHistoryCount = max(revealedHistoryCount, historyPreviewCount)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showAllHistory ? "chevron.up" : "chevron.down")
                            Text(showAllHistory ? "Show fewer sessions" : "View all \(filteredLogEntries.count) sessions")
                        }
                        .font(.custom("Inter", size: 13, relativeTo: .subheadline).weight(.semibold))
                        .foregroundColor(textMain)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(glassCard(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var emptyHistoryState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No sessions logged yet")
                .font(.custom("Inter", size: 17, relativeTo: .headline).weight(.semibold))
                .foregroundColor(textMain)
            Text("No completions or violations have been recorded.")
                .font(.custom("Inter", size: 13, relativeTo: .body).weight(.medium))
                .foregroundColor(textSecondary)
            Text("Complete a protocol from Cockpit or Planning to create your first log entry.")
                .font(.custom("Inter", size: 13, relativeTo: .body).weight(.medium))
                .foregroundColor(textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard(cornerRadius: 24))
    }

    var emptyFilteredHistoryState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No matching logs")
                .font(.custom("Inter", size: 17, relativeTo: .headline).weight(.semibold))
                .foregroundColor(textMain)
            Text("Try adjusting or clearing filters.")
                .font(.custom("Inter", size: 13, relativeTo: .body).weight(.medium))
                .foregroundColor(textSecondary)
            Button {
                Haptics.selection()
                resetFilters()
            } label: {
                Text("Clear filters")
                    .font(.custom("Inter", size: 13, relativeTo: .body).weight(.semibold))
                    .foregroundColor(textMain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(glassCard(cornerRadius: 12, muted: true))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard(cornerRadius: 24))
    }

    func timelineDayHeader(for date: Date) -> some View {
        HStack(spacing: 8) {
            Text(dayHeaderLabel(for: date))
                .font(.custom("Inter", size: 11, relativeTo: .caption).weight(.black))
                .tracking(0.6)
                .foregroundColor(textMuted)

            Rectangle()
                .fill(isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.14))
                .frame(height: 1)
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    func sessionCard(_ entry: LogEntry, index: Int, showsConnector: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(entry.iconTint.opacity(isDarkMode ? 0.18 : 0.2))
                    .frame(width: timelineIconSize, height: timelineIconSize)
                    .overlay(
                        Image(systemName: entry.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(entry.iconTint)
                    )

                if showsConnector {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isDarkMode ? Color.white.opacity(0.09) : Color.black.opacity(0.08))
                        .frame(width: 1, height: 38)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    timelineHeader(entry: entry, stacked: false)
                    timelineHeader(entry: entry, stacked: true)
                }

                if entry.type == .completion {
                    if index == 0 {
                        HStack(spacing: 8) {
                            metricPill(label: "Flow", value: "\(entry.flow)%", accent: entry.badgeColor)
                            metricPill(label: "Inter.", value: "\(entry.distractions)", accent: textMain)
                            metricPill(label: "Delta", value: entry.output, accent: isDarkMode ? magentaAccent : Color(hex: "2563EB"))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Progress")
                                .font(.custom("Inter", size: 10, relativeTo: .caption2).weight(.bold))
                                .foregroundColor(textMuted)
                            progressBar(percent: entry.goalPercent, accent: entry.badgeColor)
                        }
                    }
                } else if !entry.violationReason.isEmpty {
                    Text(entry.violationReason)
                        .font(.custom("Inter", size: 12, relativeTo: .subheadline).weight(.semibold))
                        .foregroundColor(textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(glassCard(cornerRadius: 22, muted: entry.type == .violation))
    }

    func metricPill(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.custom("Inter", size: 8, relativeTo: .caption2).weight(.bold))
                .foregroundColor(textMuted)
            Text(value)
                .font(.custom("Inter", size: 12, relativeTo: .subheadline).weight(.bold))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(metricPillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    func timelineHeader(entry: LogEntry, stacked: Bool) -> some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 8) {
                    timelineTitleTime(entry: entry)
                    timelineBadge(entry: entry)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    timelineTitleTime(entry: entry)
                    Spacer(minLength: 6)
                    timelineBadge(entry: entry)
                }
            }
        }
    }

    func timelineTitleTime(entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.title)
                .font(.custom("Inter", size: 17, relativeTo: .headline).weight(.bold))
                .foregroundColor(textMain)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.timeLabel)
                .font(.custom("Inter", size: 11, relativeTo: .caption).weight(.medium))
                .foregroundColor(textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func timelineBadge(entry: LogEntry) -> some View {
        HStack(spacing: 4) {
            Image(systemName: badgeSymbol(for: entry))
                .font(.system(size: 10, weight: .black))
            Text(entry.badge)
                .font(.custom("Inter", size: 9, relativeTo: .caption2).weight(.black))
                .tracking(0.5)
        }
        .foregroundColor(entry.badgeColor)
        .padding(.horizontal, badgeHorizontalPadding)
        .padding(.vertical, badgeVerticalPadding)
        .background(entry.badgeBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(entry.badgeStroke, lineWidth: 1)
        )
    }

    func badgeSymbol(for entry: LogEntry) -> String {
        if entry.type == .violation {
            return "xmark.octagon.fill"
        }
        return entry.badge == "EXTRA" ? "plus.circle.fill" : "checkmark.circle.fill"
    }

    func progressBar(percent: Int, accent: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(isDarkMode ? Color.white.opacity(0.07) : Color.black.opacity(0.06))

                Capsule(style: .continuous)
                    .fill(accent)
                    .frame(width: max(0, min(1, CGFloat(percent) / 100)) * proxy.size.width)
                    .shadow(color: accent.opacity(isDarkMode ? 0.4 : 0.22), radius: 6, x: 0, y: 0)
            }
        }
        .frame(height: progressBarHeight)
    }

    func shouldShowDayHeader(for index: Int) -> Bool {
        guard visibleHistoryEntries.indices.contains(index) else { return false }
        if index == 0 { return true }
        let current = visibleHistoryEntries[index].date
        let previous = visibleHistoryEntries[index - 1].date
        return DateRules.isoCalendar.isDate(current, inSameDayAs: previous) == false
    }

    func shouldShowConnector(for index: Int) -> Bool {
        guard visibleHistoryEntries.indices.contains(index) else { return false }
        let nextIndex = index + 1
        guard visibleHistoryEntries.indices.contains(nextIndex) else { return false }
        let current = visibleHistoryEntries[index].date
        let next = visibleHistoryEntries[nextIndex].date
        return DateRules.isoCalendar.isDate(current, inSameDayAs: next)
    }

    func dayHeaderLabel(for date: Date) -> String {
        if DateRules.isoCalendar.isDateInToday(date) {
            return "TODAY"
        }
        if DateRules.isoCalendar.isDateInYesterday(date) {
            return "YESTERDAY"
        }
        return CockpitLogsDateFormatters.dayHeader.string(from: date).uppercased()
    }

    var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Event / State") {
                    allEventChip
                    eventChips
                }

                Section("Time Range") {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(LogTimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedTimeRange == .custom {
                        DatePicker("Start", selection: $customStartDate, displayedComponents: [.date])
                            .onChange(of: customStartDate) { _, newValue in
                                if customEndDate < newValue {
                                    customEndDate = newValue
                                }
                            }
                        DatePicker("End", selection: $customEndDate, in: customStartDate..., displayedComponents: [.date])
                    }
                }

                Section("Protocol") {
                    Picker("Protocol", selection: $selectedProtocolId) {
                        Text("All protocols").tag(Optional<UUID>.none)
                        ForEach(protocolFilterOptions) { option in
                            Text(option.title).tag(Optional(option.id))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button("Reset all filters", role: .destructive) {
                        Haptics.selection()
                        resetFilters()
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFiltersSheet = false
                    }
                }
            }
        }
    }

    var allEventChip: some View {
        Button {
            Haptics.selection()
            selectedEventTypes = []
        } label: {
            Text("All")
                .font(.custom("Inter", size: 13, relativeTo: .body).weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(selectedEventTypes.isEmpty ? activeAccent.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedEventTypes.isEmpty ? activeAccent : textSubtle.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var eventChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(LogFilterEventType.allCases, id: \.self) { type in
                eventChip(for: type)
            }
        }
    }

    func eventChip(for type: LogFilterEventType) -> some View {
        let isSelected = selectedEventTypes.contains(type)
        return Button {
            Haptics.selection()
            if isSelected {
                selectedEventTypes.remove(type)
            } else {
                selectedEventTypes.insert(type)
            }
        } label: {
            Text(type.title)
                .font(.custom("Inter", size: 13, relativeTo: .body).weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                .background(isSelected ? activeAccent.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? activeAccent : textSubtle.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func resetFilters() {
        selectedEventTypes = []
        selectedTimeRange = .allTime
        selectedProtocolId = nil
        showAllHistory = false
        revealedHistoryCount = min(historyPreviewCount, filteredLogEntries.count)
    }
}

private extension CockpitLogsScreen {
    func runEntranceIfNeeded() {
        guard hasStartedEntrance == false else { return }
        hasStartedEntrance = true

        if didAnimateThisSession || reduceMotion {
            showIntegritySection = true
            showPerformanceSection = true
            showHistorySection = true
            revealedMatrixCount = matrixDays.count
            metricsAnimatedIn = true
            revealedHistoryCount = historyPreviewCount
            didAnimateLogsPhase1SessionID = effectiveMotionSessionID
            return
        }

        showIntegritySection = false
        showPerformanceSection = false
        showHistorySection = false
        revealedMatrixCount = 0
        metricsAnimatedIn = false
        revealedHistoryCount = 0

        MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
            showIntegritySection = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                revealedMatrixCount = matrixDays.count
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                showPerformanceSection = true
                metricsAnimatedIn = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                showHistorySection = true
            }
        }

        for index in 0..<historyPreviewCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36 + (Double(index) * 0.06)) {
                MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                    revealedHistoryCount = max(revealedHistoryCount, index + 1)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            didAnimateLogsPhase1SessionID = effectiveMotionSessionID
        }
    }

    var isDarkMode: Bool { colorScheme == .dark }
    var isRecoveryThemeActive: Bool { store.isSystemStable == false }

    var activeAccent: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171") : Color(hex: "B91C1C")
        }
        return isDarkMode ? cyanAccent : Color(hex: "2563EB")
    }
    var cyanAccent: Color { Color(hex: "00F2FF") }
    var magentaAccent: Color { Color(hex: "FF00E5") }

    var navItemColor: Color { isDarkMode ? Theme.Colors.textSecondary : Color(hex: "111827") }

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
                        colors: [Color(hex: "DC2626").opacity(0.32), .clear],
                        center: UnitPoint(x: 0.5, y: -0.08),
                        startRadius: 0,
                        endRadius: 420
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

    func glassCard(cornerRadius: CGFloat, muted: Bool = false) -> some View {
        let fill: Color = {
            if isRecoveryThemeActive {
                if isDarkMode {
                    return Color(hex: "1B0A0D").opacity(muted ? 0.38 : 0.56)
                }
                return Color.white.opacity(muted ? 0.68 : 0.84)
            }
            if isDarkMode {
                return Color(hex: "0F172A").opacity(muted ? 0.3 : 0.42)
            }
            return Color.white.opacity(muted ? 0.58 : 0.72)
        }()

        let stroke: Color = {
            if isRecoveryThemeActive {
                return isDarkMode ? Color(hex: "F87171").opacity(0.32) : Color(hex: "FCA5A5").opacity(0.72)
            }
            return isDarkMode ? Color.white.opacity(0.1) : Color(hex: "B9C7D7").opacity(0.72)
        }()

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }

    var textMain: Color { isDarkMode ? .white : Color(hex: "0B1220") }
    var textSecondary: Color { isDarkMode ? Color.white.opacity(0.84) : Color(hex: "374151") }
    var textMuted: Color { isDarkMode ? Color.white.opacity(0.74) : Color(hex: "475569") }
    var textSubtle: Color { isDarkMode ? Color.white.opacity(0.68) : Color(hex: "546174") }
    var historyPreviewCount: Int { 6 }
    var visibleHistoryEntries: [LogEntry] {
        Array(filteredLogEntries.prefix(showAllHistory ? filteredLogEntries.count : historyPreviewCount))
    }
    var weekdayHeaders: [String] { ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] }

    var adherencePillBackground: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "EF4444").opacity(0.16) : Color(hex: "FEE2E2")
        }
        if isDarkMode { return cyanAccent.opacity(0.12) }
        return Color(hex: "D9F99D")
    }

    var adherencePillStroke: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171").opacity(0.35) : Color(hex: "FCA5A5")
        }
        if isDarkMode { return cyanAccent.opacity(0.35) }
        return Color(hex: "B7E269")
    }

    var adherenceTextColor: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "FCA5A5") : Color(hex: "B91C1C")
        }
        if isDarkMode { return cyanAccent }
        return Color(hex: "1F2937")
    }

    var metricPillBackground: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "2A1116").opacity(0.5) : Color(hex: "FEE2E2").opacity(0.72)
        }
        return isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04)
    }

    var matrixIdleFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color(hex: "60A5FA").opacity(0.18)
    }

    var matrixHighFill: Color {
        isDarkMode ? Color(hex: "22D3EE").opacity(0.82) : Color(hex: "38BDF8")
    }

    var matrixMediumFill: Color {
        isDarkMode ? Color(hex: "06B6D4").opacity(0.68) : Color(hex: "7DD3FC")
    }

    var matrixViolationFill: Color {
        isDarkMode ? Color(hex: "EF4444").opacity(0.36) : Color(hex: "FCA5A5")
    }

    var matrixUnproductiveFill: Color {
        isDarkMode ? Color(hex: "DC2626").opacity(0.22) : Color(hex: "FECACA")
    }

    var todayOutlineColor: Color {
        if isRecoveryThemeActive {
            return isDarkMode ? Color(hex: "F87171") : Color(hex: "B91C1C")
        }
        return isDarkMode ? cyanAccent : Color(hex: "60A5FA")
    }

    func matrixFill(for point: MatrixDay) -> Color {
        if point.isStrongRed {
            return matrixViolationFill
        }
        if point.unproductive {
            return matrixUnproductiveFill
        }

        if point.completionCount == 0 && point.extraCount > 0 {
            return isDarkMode ? Color(hex: "FDE047").opacity(0.8) : Color(hex: "FDE68A")
        }

        if point.completionCount >= 2 {
            return matrixMediumFill
        }

        if point.isBlueDay {
            return matrixHighFill
        }

        return matrixIdleFill
    }

    func matrixStroke(for point: MatrixDay) -> Color {
        if point.isStrongRed {
            return Color(hex: "EF4444").opacity(isDarkMode ? 0.9 : 0.7)
        }
        if point.unproductive {
            return isDarkMode ? Color(hex: "FCA5A5").opacity(0.72) : Color(hex: "DC2626").opacity(0.52)
        }
        if point.completionCount == 0 && point.extraCount > 0 {
            return isDarkMode ? Color(hex: "FDE047").opacity(0.98) : Color(hex: "CA8A04").opacity(0.9)
        }
        if point.completionCount >= 2 {
            return isDarkMode ? Color(hex: "67E8F9") : Color(hex: "0EA5E9").opacity(0.9)
        }
        if point.isBlueDay {
            return isDarkMode ? Color(hex: "22D3EE").opacity(0.98) : Color(hex: "0284C7").opacity(0.9)
        }
        return isDarkMode ? Color.white.opacity(0.08) : Color(hex: "60A5FA").opacity(0.16)
    }

    func matrixGlow(for point: MatrixDay) -> Color {
        guard isDarkMode else { return .clear }
        if point.isStrongRed { return .clear }
        if point.unproductive { return Color(hex: "FCA5A5").opacity(0.22) }
        if point.completionCount == 0 && point.extraCount > 0 {
            return Color(hex: "FDE047").opacity(0.72)
        }
        if point.completionCount >= 2 {
            return Color(hex: "67E8F9").opacity(0.8)
        }
        if point.isBlueDay {
            return Color(hex: "22D3EE").opacity(0.65)
        }
        return .clear
    }

    func matrixToken(for point: MatrixDay) -> String? {
        if point.isStrongRed { return "V" }
        if point.unproductive { return "U" }
        if point.completionCount == 0 && point.extraCount > 0 { return "E" }
        if point.isBlueDay { return "C" }
        return nil
    }

    func dayNumberText(for date: Date) -> String {
        String(DateRules.isoCalendar.component(.day, from: date))
    }

    func dayNumberColor(for point: MatrixDay) -> Color {
        if point.isToday {
            return isDarkMode ? Color.white : Color(hex: "0F172A")
        }
        if point.isStrongRed {
            return isDarkMode ? Color.red.opacity(0.88) : Color(hex: "B91C1C")
        }
        if point.unproductive {
            return isDarkMode ? Color(hex: "FCA5A5") : Color(hex: "991B1B")
        }
        return isDarkMode ? Color.white.opacity(0.72) : Color(hex: "334155")
    }

    func cornerIndicatorColor(for point: MatrixDay) -> Color? {
        if point.isStrongRed {
            if point.completionCount > 0 {
                return isDarkMode ? cyanAccent : Color(hex: "1D4ED8")
            }
            if point.extraCount > 0 {
                return isDarkMode ? Color(hex: "FDE047") : Color(hex: "A16207")
            }
            return nil
        }

        if point.completionCount > 0 && point.extraCount > 0 {
            return isDarkMode ? Color(hex: "FDE047") : Color(hex: "A16207")
        }
        return nil
    }

    var adherence: Int {
        guard !matrixDays.isEmpty else { return 0 }
        let completedDays = matrixDays.filter { $0.isBlueDay }.count
        return Int((Double(completedDays) / Double(matrixDays.count) * 100).rounded())
    }

    var deepFocusHours: Double {
        let weeklyCompletions = visibleCountedCompletions.filter {
            DateRules.weekID(for: $0.date) == DateRules.weekID(for: appClock.now)
        }.count
        let estimate = max(2.6, 2.0 + (Double(weeklyCompletions) * 0.45))
        return min(9.8, estimate)
    }

    var neuralSyncPercent: Int {
        min(99, max(74, adherence + 4))
    }

    var deepFocusBars: [Double] {
        let base = Double(max(1, store.currentStreakDays(referenceDate: appClock.now) % 7))
        return [
            0.28,
            0.42,
            0.24 + (base * 0.02),
            0.88,
            0.62
        ]
    }

    var neuralSyncBars: [Double] {
        let factor = Double(max(1, adherence % 10)) / 100
        return [
            0.48,
            0.92,
            0.35 + factor,
            0.28 + factor
        ]
    }

    var matrixDays: [MatrixDay] {
        store.logsCalendarSignals(lastDays: 28, referenceDate: appClock.now).map { signal in
            MatrixDay(
                day: signal.day,
                completionCount: signal.completionCount,
                extraCount: signal.extraCount,
                violationCount: signal.violationCount,
                unproductive: signal.unproductive,
                noWorkRequiredSatisfied: signal.noWorkRequiredSatisfied,
                inevitableWeeklyMiss: signal.inevitableWeeklyMiss,
                isToday: signal.isToday
            )
        }
    }

    var allLogEntries: [LogEntry] {
        let completionEntries = visibleCompletions.map { completion in
            let goal = 68 + (abs(Int(completion.date.timeIntervalSince1970 / 60)) % 31)
            let isExtra = completion.kind == .extra
            let owner = owner(for: completion)
            return LogEntry(
                type: .completion,
                date: completion.date,
                title: title(for: completion),
                protocolId: owner?.id,
                protocolTitle: owner?.definition.title ?? "Protocol Session",
                badge: isExtra ? "EXTRA" : (isDarkMode ? "SYNCED" : "COMPLETED"),
                badgeColor: isExtra
                    ? (isDarkMode ? Color(hex: "FDE047") : Color(hex: "A16207"))
                    : (isDarkMode ? cyanAccent : Color(hex: "15803D")),
                badgeBackground: isExtra
                    ? (isDarkMode ? Color(hex: "FDE047").opacity(0.14) : Color(hex: "FEF3C7"))
                    : (isDarkMode ? cyanAccent.opacity(0.1) : Color(hex: "DCFCE7")),
                badgeStroke: isExtra
                    ? (isDarkMode ? Color(hex: "FDE047").opacity(0.42) : Color(hex: "FCD34D"))
                    : (isDarkMode ? cyanAccent.opacity(0.35) : Color(hex: "86EFAC")),
                icon: completionIcon(for: completion),
                iconTint: isExtra
                    ? (isDarkMode ? Color(hex: "FDE047") : Color(hex: "A16207"))
                    : (isDarkMode ? cyanAccent : Color(hex: "1D4ED8")),
                timeLabel: timeLabel(for: completion.date),
                flow: deterministicFlow(for: completion.date),
                distractions: deterministicDistractions(for: completion.date),
                output: deterministicOutput(for: completion.date),
                goalPercent: goal,
                violationReason: "",
                eventType: isExtra ? .extra : .completed,
                isRecoveryRelated: owner.map(isRecoveryRelated(owner:)) ?? false
            )
        }

        let violationEntries = visibleViolations.map { violation in
            let owner = owner(for: violation)
            return LogEntry(
                type: .violation,
                date: violation.date,
                title: title(for: violation),
                protocolId: owner?.id,
                protocolTitle: owner?.definition.title ?? "Review Cycle",
                badge: "ABORTED",
                badgeColor: isDarkMode ? Color(hex: "F87171") : Color(hex: "DC2626"),
                badgeBackground: isDarkMode ? Color.red.opacity(0.12) : Color.red.opacity(0.08),
                badgeStroke: isDarkMode ? Color.red.opacity(0.26) : Color.red.opacity(0.2),
                icon: "exclamationmark",
                iconTint: isDarkMode ? Color(hex: "F87171") : Color(hex: "DC2626"),
                timeLabel: timeLabel(for: violation.date),
                flow: 0,
                distractions: 0,
                output: "",
                goalPercent: 0,
                violationReason: violationReason(violation.kind),
                eventType: .violated,
                isRecoveryRelated: owner.map(isRecoveryRelated(owner:)) ?? false
            )
        }

        return (completionEntries + violationEntries)
            .sorted { $0.date > $1.date }
    }

    var filteredLogEntries: [LogEntry] {
        allLogEntries.filter { entry in
            matchesEventFilter(entry)
                && matchesTimeFilter(entry.date)
                && matchesProtocolFilter(entry)
        }
    }

    var protocolFilterOptions: [ProtocolFilterOption] {
        var optionsById: [UUID: String] = [:]
        for entry in allLogEntries {
            guard let id = entry.protocolId else { continue }
            if optionsById[id] == nil {
                optionsById[id] = entry.protocolTitle
            }
        }
        return optionsById
            .map { ProtocolFilterOption(id: $0.key, title: $0.value) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var filterSummary: LogFilterSummary {
        var parts: [String] = []
        if selectedEventTypes.isEmpty == false {
            let eventText = selectedEventTypes
                .sorted { $0.title < $1.title }
                .map(\.title)
                .joined(separator: ", ")
            parts.append(eventText)
        }
        if selectedTimeRange != .allTime {
            parts.append(selectedTimeRange.summaryText(start: customStartDate, end: customEndDate))
        }
        if let selectedProtocolId,
           let protocolTitle = protocolFilterOptions.first(where: { $0.id == selectedProtocolId })?.title {
            parts.append(protocolTitle)
        }
        return LogFilterSummary(isActive: parts.isEmpty == false, label: parts.joined(separator: " · "))
    }

    func matchesEventFilter(_ entry: LogEntry) -> Bool {
        if selectedEventTypes.isEmpty {
            return true
        }
        if selectedEventTypes.contains(entry.eventType) {
            return true
        }
        if selectedEventTypes.contains(.recoveryRelated), entry.isRecoveryRelated {
            return true
        }
        return false
    }

    func matchesTimeFilter(_ date: Date) -> Bool {
        switch selectedTimeRange {
        case .allTime:
            return true
        case .today:
            return DateRules.isoCalendar.isDateInToday(date)
        case .last7Days:
            guard let start = DateRules.isoCalendar.date(byAdding: .day, value: -6, to: DateRules.startOfDay(appClock.now, calendar: DateRules.isoCalendar)) else {
                return true
            }
            return date >= start && date <= appClock.now
        case .last30Days:
            guard let start = DateRules.isoCalendar.date(byAdding: .day, value: -29, to: DateRules.startOfDay(appClock.now, calendar: DateRules.isoCalendar)) else {
                return true
            }
            return date >= start && date <= appClock.now
        case .custom:
            let start = DateRules.startOfDay(customStartDate, calendar: DateRules.isoCalendar)
            let dayAfterEnd = DateRules.isoCalendar.date(byAdding: .day, value: 1, to: DateRules.startOfDay(customEndDate, calendar: DateRules.isoCalendar)) ?? customEndDate
            return date >= start && date < dayAfterEnd
        }
    }

    func matchesProtocolFilter(_ entry: LogEntry) -> Bool {
        guard let selectedProtocolId else { return true }
        return entry.protocolId == selectedProtocolId
    }

    // Keep Logs aligned with "today" by hiding future-dated records.
    // Future records can exist in debug sessions when simulated time was advanced.
    var visibleCompletions: [CompletionRecord] {
        store.completionLog.filter { $0.date <= appClock.now }
    }

    var visibleCountedCompletions: [CompletionRecord] {
        visibleCompletions.filter { $0.kind == .counted }
    }

    var visibleExtraCompletions: [CompletionRecord] {
        visibleCompletions.filter { $0.kind == .extra }
    }

    var visibleViolations: [Violation] {
        store.violationLog.filter { $0.date <= appClock.now }
    }

    func completionIcon(for completion: CompletionRecord) -> String {
        if let owner = owner(for: completion) {
            return ProtocolIconCatalog.resolvedSymbolName(owner.definition.iconSystemName, fallback: "waveform.path.ecg")
        }
        return "waveform.path.ecg"
    }

    func title(for completion: CompletionRecord) -> String {
        if let owner = owner(for: completion) {
            return owner.definition.title
        }
        return "Protocol Session"
    }

    func title(for violation: Violation) -> String {
        if let owner = owner(for: violation) {
            return owner.definition.title
        }
        return "Review Cycle"
    }

    func owner(for completion: CompletionRecord) -> NonNegotiable? {
        store.system.nonNegotiables.first(where: { $0.completions.contains(completion) })
    }

    func owner(for violation: Violation) -> NonNegotiable? {
        store.system.nonNegotiables.first(where: { $0.violations.contains(violation) })
    }

    func isRecoveryRelated(owner: NonNegotiable) -> Bool {
        owner.state == .recovery || owner.state == .suspended
    }

    func violationReason(_ kind: ViolationKind) -> String {
        switch kind {
        case .missedWeeklyFrequency:
            return "Missed weekly target"
        case .missedDailyCompliance:
            return "Missed daily compliance"
        }
    }

    func deterministicFlow(for date: Date) -> Int {
        84 + (abs(Int(date.timeIntervalSince1970)) % 15)
    }

    func deterministicDistractions(for date: Date) -> Int {
        abs(Int(date.timeIntervalSince1970 / 60)) % 4
    }

    func deterministicOutput(for date: Date) -> String {
        let flow = deterministicFlow(for: date)
        if flow >= 95 { return "High" }
        if flow >= 89 { return "Good" }
        return "Medium"
    }

    func timeLabel(for date: Date) -> String {
        CockpitLogsDateFormatters.time.string(from: date)
    }
}

private struct MatrixDay: Identifiable {
    let day: Date
    let completionCount: Int
    let extraCount: Int
    let violationCount: Int
    let unproductive: Bool
    let noWorkRequiredSatisfied: Bool
    let inevitableWeeklyMiss: Bool
    let isToday: Bool

    var id: Date { day }
    var isStrongRed: Bool { violationCount > 0 || inevitableWeeklyMiss }
    var isBlueDay: Bool { completionCount > 0 || noWorkRequiredSatisfied }
}

private struct LogEntry: Identifiable {
    enum EntryType {
        case completion
        case violation
    }

    let type: EntryType
    let date: Date
    let title: String
    let protocolId: UUID?
    let protocolTitle: String
    let badge: String
    let badgeColor: Color
    let badgeBackground: Color
    let badgeStroke: Color
    let icon: String
    let iconTint: Color
    let timeLabel: String
    let flow: Int
    let distractions: Int
    let output: String
    let goalPercent: Int
    let violationReason: String
    let eventType: LogFilterEventType
    let isRecoveryRelated: Bool

    var id: String {
        "\(date.timeIntervalSince1970)-\(title)-\(badge)"
    }
}

private enum LogFilterEventType: CaseIterable, Hashable {
    case completed
    case violated
    case extra
    case recoveryRelated

    var title: String {
        switch self {
        case .completed:
            return "Completed"
        case .violated:
            return "Missed / Violated"
        case .extra:
            return "Extra"
        case .recoveryRelated:
            return "Recovery-related"
        }
    }
}

private enum LogTimeRange: CaseIterable, Hashable {
    case allTime
    case today
    case last7Days
    case last30Days
    case custom

    var title: String {
        switch self {
        case .allTime:
            return "All time"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 days"
        case .last30Days:
            return "Last 30 days"
        case .custom:
            return "Custom range"
        }
    }

    func summaryText(start: Date, end: Date) -> String {
        switch self {
        case .allTime:
            return "All time"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 days"
        case .last30Days:
            return "Last 30 days"
        case .custom:
            return "\(CockpitLogsDateFormatters.shortDay.string(from: start))-\(CockpitLogsDateFormatters.shortDay.string(from: end))"
        }
    }
}

private struct ProtocolFilterOption: Identifiable, Hashable {
    let id: UUID
    let title: String
}

private struct LogFilterSummary: Equatable {
    let isActive: Bool
    let label: String
}

private enum CockpitLogsDateFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter
    }()

    static let dayHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    static let shortDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}
