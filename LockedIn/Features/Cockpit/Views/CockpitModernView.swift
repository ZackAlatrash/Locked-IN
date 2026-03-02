import SwiftUI

enum CockpitModernStyle: String, CaseIterable {
    case light
    case dark
}

struct CockpitModernView: View {
    let style: CockpitModernStyle
    let accentColor: Color
    let weeklyAccentColor: Color
    let streakAccentColor: Color
    let reliabilityScore: Int
    let modeText: String
    let recoveryProgressText: String?
    let capacityStatusText: String
    let activeCapacityCountText: String
    let pendingCount: Int
    let streakDays: Int
    let protocolLoad: Double
    let todayCompleted: Bool
    let todayCompletionCount: Int
    let weeklyCompletionCount: Int
    let weeklyTargetCount: Int
    let weeklyCompletionByDay: [Int]
    let capacityProtocols: [TodayTask]
    let showEmbeddedHeader: Bool
    let onWeeklyActivityTap: () -> Void
    let onStreakTap: () -> Void
    let onCapacityTap: () -> Void
    let onProtocolComplete: (UUID) -> Void
    let onProtocolTap: (UUID) -> Void

    init(
        style: CockpitModernStyle,
        accentColor: Color = Color(hex: "06B6D4"),
        weeklyAccentColor: Color? = nil,
        streakAccentColor: Color? = nil,
        reliabilityScore: Int,
        modeText: String,
        recoveryProgressText: String?,
        capacityStatusText: String,
        activeCapacityCountText: String,
        pendingCount: Int,
        streakDays: Int,
        protocolLoad: Double,
        todayCompleted: Bool,
        todayCompletionCount: Int,
        weeklyCompletionCount: Int,
        weeklyTargetCount: Int,
        weeklyCompletionByDay: [Int],
        capacityProtocols: [TodayTask],
        showEmbeddedHeader: Bool = true,
        onWeeklyActivityTap: @escaping () -> Void = {},
        onStreakTap: @escaping () -> Void = {},
        onCapacityTap: @escaping () -> Void = {},
        onProtocolComplete: @escaping (UUID) -> Void = { _ in },
        onProtocolTap: @escaping (UUID) -> Void = { _ in }
    ) {
        self.style = style
        self.accentColor = accentColor
        self.weeklyAccentColor = weeklyAccentColor ?? accentColor
        self.streakAccentColor = streakAccentColor ?? accentColor
        self.reliabilityScore = reliabilityScore
        self.modeText = modeText
        self.recoveryProgressText = recoveryProgressText
        self.capacityStatusText = capacityStatusText
        self.activeCapacityCountText = activeCapacityCountText
        self.pendingCount = pendingCount
        self.streakDays = streakDays
        self.protocolLoad = protocolLoad
        self.todayCompleted = todayCompleted
        self.todayCompletionCount = todayCompletionCount
        self.weeklyCompletionCount = weeklyCompletionCount
        self.weeklyTargetCount = weeklyTargetCount
        self.weeklyCompletionByDay = weeklyCompletionByDay
        self.capacityProtocols = capacityProtocols
        self.showEmbeddedHeader = showEmbeddedHeader
        self.onWeeklyActivityTap = onWeeklyActivityTap
        self.onStreakTap = onStreakTap
        self.onCapacityTap = onCapacityTap
        self.onProtocolComplete = onProtocolComplete
        self.onProtocolTap = onProtocolTap
    }

    private var primary: Color { accentColor }
    private var background: Color { style == .light ? Color(hex: "F2F2F7") : Color.black }
    private var card: Color { style == .light ? Color.white : Color(hex: "1C1C1E") }
    private var textMain: Color { style == .light ? Color(hex: "101827") : Color.white }
    private var textSecondary: Color { style == .light ? Color(hex: "6B7280") : Color.white.opacity(0.55) }
    private var subtleStroke: Color { style == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.05) }
    private var topContentPadding: CGFloat { showEmbeddedHeader ? 58 : 10 }

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if showEmbeddedHeader {
                        header
                    }
                    reliabilityCard
                    metricCards
                    capacityCard
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, topContentPadding)
            }
        }
    }
}

private extension CockpitModernView {
    var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cockpit")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(textMain)
                Text("WEDNESDAY, SEP 24")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.2)
                    .foregroundColor(textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(style == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.09))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(primary)
            }
        }
    }

    var reliabilityCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Reliability")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(textMain)
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .foregroundColor(primary)
                }

                HStack(spacing: 20) {
                    scoreRing

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT MODE")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textSecondary)
                            Text(modeText.capitalized)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(primary)
                            if let recoveryProgressText {
                                Text(recoveryProgressText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(todayCompleted ? "TODAY" : "PENDING")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textSecondary)
                            HStack(spacing: 6) {
                                Text(todayCompleted ? "Completed" : "\(pendingCount) Protocols")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(textMain)
                                if !todayCompleted && pendingCount > 0 {
                                    Text("!")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(hex: "F43F5E"))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(style == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.15), lineWidth: 12)
                .frame(width: 138, height: 138)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(reliabilityScore, 100))) / 100)
                .stroke(primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 138, height: 138)

            VStack(spacing: 2) {
                Text("\(reliabilityScore)")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(textMain)
                Text("SCORE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textSecondary)
            }
        }
    }

    var metricCards: some View {
        HStack(spacing: 12) {
            roundedCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Activity")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textMain)
                            Text("Today")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(textSecondary)
                    }
                    Text("\(todayCompletionCount) DONE")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(weeklyAccentColor)
                    Text("\(weeklyCompletionCount)/\(max(weeklyTargetCount, 1)) this week")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary)
                    Spacer()
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(weeklyCompletionByDay.enumerated()), id: \.offset) { index, count in
                            let maxCount = max(weeklyCompletionByDay.max() ?? 1, 1)
                            let heightFactor = CGFloat(count) / CGFloat(maxCount)

                            VStack(spacing: 6) {
                                bar(
                                    max(heightFactor, 0.12),
                                    active: index == currentWeekdayIndex,
                                    accent: weeklyAccentColor
                                )
                                Text(dayLabel(for: index))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(height: 84)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onWeeklyActivityTap)

            roundedCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textMain)
                            Text("Current")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(textSecondary)
                    }
                    Spacer(minLength: 4)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(streakDays)")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(streakAccentColor)
                        Text("DAYS")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textSecondary)
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 10) {
                        Circle()
                            .fill(streakAccentColor.opacity(0.2))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: todayCompleted ? "checkmark" : "clock.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(streakAccentColor)
                            )
                        Text(todayCompleted ? "Today completed (\(todayCompletionCount))" : "No completion today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textMain)
                        Spacer()
                    }
                    .padding(10)
                    .background(style == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onStreakTap)
        }
        .frame(height: 238)
    }

    var capacityCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Protocol Capacity")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(textMain)
                    Spacer()
                    Button {
                        onCapacityTap()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("Load")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primary)
                    Spacer()
                    Text("\(Int(protocolLoad * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textSecondary)
                }

                HStack {
                    Text(activeCapacityCountText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(textMain)
                    Spacer()
                    Text(capacityStatusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(style == .light ? Color.black.opacity(0.10) : Color.white.opacity(0.16))
                        Capsule()
                            .fill(primary)
                            .frame(width: geo.size.width * max(0, min(protocolLoad, 1)))
                    }
                }
                .frame(height: 14)

                Text("ACTIVE PROTOCOLS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textSecondary)

                if capacityProtocols.isEmpty {
                    Text("No active protocols")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textSecondary)
                } else {
                    ForEach(capacityProtocols.prefix(4)) { task in
                        protocolRow(task)
                    }
                }
            }
        }
    }

    func protocolRow(_ task: TodayTask) -> some View {
        HStack {
            Circle()
                .fill(primary.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: task.isCompleteToday ? "checkmark" : "bolt.fill")
                        .foregroundColor(primary)
                        .font(.system(size: 12, weight: .bold))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textMain)
                Text(task.statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSecondary)
            }
            Spacer()
            Button(task.ctaTitle) {
                onProtocolComplete(task.nnId)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(primary.opacity(0.2)))
            .overlay(Capsule().stroke(primary.opacity(0.4), lineWidth: 1))
            .foregroundColor(task.isCtaEnabled ? primary : textSecondary)
            .buttonStyle(.plain)
            .disabled(!task.isCtaEnabled)
        }
        .padding(10)
        .background(style == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            onProtocolTap(task.nnId)
        }
    }

    func roundedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(subtleStroke, lineWidth: 1)
            )
            .shadow(
                color: style == .light ? Color.black.opacity(0.10) : Color.black.opacity(0.24),
                radius: style == .light ? 10 : 16,
                x: 0,
                y: style == .light ? 4 : 8
            )
    }

    func bar(_ heightFactor: CGFloat, active: Bool, accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(active ? accent : (style == .light ? Color.black.opacity(0.16) : Color.white.opacity(0.16)))
            .frame(width: 10, height: max(8, 64 * heightFactor))
    }

    func dayLabel(for index: Int) -> String {
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        guard labels.indices.contains(index) else { return "" }
        return labels[index]
    }

    var currentWeekdayIndex: Int {
        let weekday = DateRules.isoCalendar.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

}
