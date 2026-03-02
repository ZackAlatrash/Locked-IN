import SwiftUI

struct CockpitLogsScreen: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject private var store: CommitmentSystemStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showProfile = false

    private var matrixColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    init(selectedTab: Binding<MainTab> = .constant(.logs)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    integrityMatrixCard
                    sessionHistory
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Diagnostic Log")
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
                            .fill(accentGreen)
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
    }
}

private extension CockpitLogsScreen {
    var header: some View {
        Text("LOCKEDIN: NEURAL INTERFACE")
            .font(.custom("Inter", size: 12).weight(.semibold))
            .tracking(1.3)
            .foregroundColor(textMuted)
            .padding(.horizontal, 2)
        .padding(.top, 8)
    }

    var integrityMatrixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("35-DAY INTEGRITY MATRIX")
                    .font(.custom("Inter", size: 11).weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(textMuted)

                Spacer()

                Text("\(adherence)% ADHERENCE")
                    .font(.custom("Inter", size: 11).weight(.bold))
                    .foregroundColor(accentGreen)
            }

            LazyVGrid(columns: matrixColumns, spacing: 6) {
                ForEach(matrixDays) { point in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(matrixFill(for: point))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(point.violationCount > 0 ? accentRed.opacity(0.7) : .clear, lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(accentGreen.opacity(point.isToday ? 0.9 : 0), lineWidth: point.isToday ? 2 : 0)
                                .padding(point.isToday ? -2 : 0)
                        )
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            HStack {
                ForEach(1...5, id: \.self) { week in
                    Text(String(format: "WEEK %02d", week))
                        .font(.custom("Inter", size: 10).weight(.bold))
                        .foregroundColor(textSubtle)
                    if week < 5 { Spacer(minLength: 0) }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session History")
                .font(.custom("Inter", size: 21).weight(.bold))
                .foregroundColor(textMain)
                .padding(.horizontal, 2)

            if recentEntries.isEmpty {
                emptyHistoryState
            } else {
                ForEach(Array(recentEntries.prefix(8).enumerated()), id: \.offset) { _, entry in
                    sessionCard(entry)
                }
            }
        }
    }

    var emptyHistoryState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No sessions logged yet")
                .font(.custom("Inter", size: 17).weight(.semibold))
                .foregroundColor(textMain)
            Text("Completions and violations will appear here as your timeline fills in.")
                .font(.custom("Inter", size: 13).weight(.medium))
                .foregroundColor(textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    func sessionCard(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 8) {
                Circle()
                    .fill(entry.tint.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: entry.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(entry.tint)
                    )

                if entry.type == .completion {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(dividerColor)
                        .frame(width: 2, height: 44)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(.custom("Inter", size: 18).weight(.bold))
                            .foregroundColor(textMain)

                        Text(entry.timeLabel)
                            .font(.custom("Inter", size: 12).weight(.medium))
                            .foregroundColor(textMuted)
                    }

                    Spacer(minLength: 8)

                    Text(entry.badge)
                        .font(.custom("Inter", size: 10).weight(.bold))
                        .tracking(0.6)
                        .foregroundColor(entry.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(entry.tint.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(entry.tint.opacity(0.24), lineWidth: 1)
                        )
                }

                if entry.type == .completion {
                    HStack(spacing: 8) {
                        metricPill(label: "Flow", value: "\(entry.flow)%")
                        metricPill(label: "Distr.", value: "\(entry.distractions)")
                        metricPill(label: "Output", value: entry.output)
                    }
                } else {
                    Text(entry.violationReason)
                        .font(.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(textSecondary)
                }
            }
        }
        .padding(14)
        .background(cardBackground.opacity(entry.type == .violation ? 0.8 : 1))
    }

    func metricPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.custom("Inter", size: 10).weight(.bold))
                .foregroundColor(textMuted)
            Text(value)
                .font(.custom("Inter", size: 13).weight(.bold))
                .foregroundColor(textMain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(metricPillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

}

private extension CockpitLogsScreen {
    var isDarkMode: Bool { colorScheme == .dark }
    var accentGreen: Color { isDarkMode ? Color(hex: "#A3FF12") : Color(hex: "#7BA70A") }
    var accentRed: Color { isDarkMode ? Color(hex: "#FF2D55") : Color(hex: "#D81B45") }
    var navItemColor: Color { isDarkMode ? Theme.Colors.textSecondary : Color(hex: "111827") }
    var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    var textMain: Color { isDarkMode ? Color.white : Color(hex: "101827") }
    var textSecondary: Color { isDarkMode ? Color.white.opacity(0.62) : Color(hex: "6B7280") }
    var textMuted: Color { isDarkMode ? Color.white.opacity(0.48) : Color(hex: "94A3B8") }
    var textSubtle: Color { isDarkMode ? Color.white.opacity(0.35) : Color(hex: "9CA3AF") }
    var dividerColor: Color { isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12) }
    var metricPillBackground: Color { isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(isDarkMode ? Color(hex: "#1C1C1E") : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
            )
    }

    var adherence: Int {
        guard !matrixDays.isEmpty else { return 0 }
        let completedDays = matrixDays.filter { $0.completionCount > 0 }.count
        return Int((Double(completedDays) / Double(matrixDays.count) * 100).rounded())
    }

    var matrixDays: [MatrixDay] {
        let calendar = DateRules.isoCalendar
        let today = DateRules.startOfDay(Date(), calendar: calendar)
        let completionByDay = Dictionary(grouping: store.completionLog) {
            DateRules.startOfDay($0.date, calendar: calendar)
        }
        let violationByDay = Dictionary(grouping: store.violationLog) {
            DateRules.startOfDay($0.date, calendar: calendar)
        }

        return (0..<35).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset - 34, to: today) else { return nil }
            let completions = completionByDay[day]?.count ?? 0
            let violations = violationByDay[day]?.count ?? 0
            return MatrixDay(day: day, completionCount: completions, violationCount: violations, isToday: day == today)
        }
    }

    func matrixFill(for point: MatrixDay) -> Color {
        if point.violationCount > 0 {
            return accentRed.opacity(0.28)
        }

        if point.completionCount > 0 {
            let boost = min(Double(point.completionCount) * 0.18, 0.55)
            return accentGreen.opacity(0.35 + boost)
        }

        return isDarkMode ? Color.white.opacity(0.09) : Color.black.opacity(0.10)
    }

    var recentEntries: [LogEntry] {
        let completionEntries = store.completionLog.map { completion in
            LogEntry(
                type: .completion,
                date: completion.date,
                title: title(for: completion),
                badge: "COMPLETED",
                tint: accentGreen,
                icon: "terminal.fill",
                timeLabel: timeLabel(for: completion.date),
                flow: deterministicFlow(for: completion.date),
                distractions: deterministicDistractions(for: completion.date),
                output: deterministicOutput(for: completion.date),
                violationReason: ""
            )
        }

        let violationEntries = store.violationLog.map { violation in
            LogEntry(
                type: .violation,
                date: violation.date,
                title: title(for: violation),
                badge: "ABORTED",
                tint: accentRed,
                icon: "exclamationmark.triangle.fill",
                timeLabel: timeLabel(for: violation.date),
                flow: 0,
                distractions: 0,
                output: "",
                violationReason: violationReason(violation.kind)
            )
        }

        return (completionEntries + violationEntries)
            .sorted { $0.date > $1.date }
    }

    func title(for completion: CompletionRecord) -> String {
        if let owner = store.system.nonNegotiables.first(where: { $0.completions.contains(completion) }) {
            return owner.definition.title
        }
        return "Protocol Session"
    }

    func title(for violation: Violation) -> String {
        if let owner = store.system.nonNegotiables.first(where: { $0.violations.contains(violation) }) {
            return owner.definition.title
        }
        return "Review Cycle"
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
    let violationCount: Int
    let isToday: Bool

    var id: Date { day }
}

private struct LogEntry {
    enum EntryType {
        case completion
        case violation
    }

    let type: EntryType
    let date: Date
    let title: String
    let badge: String
    let tint: Color
    let icon: String
    let timeLabel: String
    let flow: Int
    let distractions: Int
    let output: String
    let violationReason: String
}

private enum CockpitLogsDateFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter
    }()
}
