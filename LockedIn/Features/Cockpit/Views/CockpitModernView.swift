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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("phase1MotionSessionID") private var motionSessionID = ""
    @AppStorage("didAnimateCockpitPhase1SessionID") private var didAnimateCockpitPhase1SessionID = ""

    @State private var hasStartedEntrance = false
    @State private var showReliabilityModule = false
    @State private var showWeeklyStrip = false
    @State private var showActiveSection = false
    @State private var revealedProtocolRows = 0
    @State private var animatedReliabilityValue: Double = 0

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

    private var primary: Color { style == .dark ? Color(hex: "00F2FF") : Color(hex: "3B82F6") }
    private var bgTop: Color { Color(hex: "1A243D") }
    private var bgBottom: Color { Color(hex: "020617") }
    private var glassCard: Color {
        style == .dark ? Color(hex: "0F172A").opacity(0.42) : Color.white.opacity(0.72)
    }
    private var glassStroke: Color {
        style == .dark ? Color.white.opacity(0.09) : Color(hex: "B9C7D7").opacity(0.78)
    }
    private var textMain: Color { style == .dark ? .white : Color(hex: "0B1220") }
    private var textSecondary: Color { style == .dark ? Color.white.opacity(0.45) : Color(hex: "5B6778") }
    private var subtleCard: Color { style == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.035) }
    private var ringTrack: Color { style == .dark ? Color.white.opacity(0.08) : Color(hex: "94A3B8").opacity(0.3) }
    private var ringSize: CGFloat { 222 }
    private var ringStroke: CGFloat { 14 }
    private var ringValueTextColor: Color { style == .dark ? primary : Color(hex: "111827") }
    private var ringMetaTextColor: Color { style == .dark ? primary : Color(hex: "374151") }
    private var topPadding: CGFloat { showEmbeddedHeader ? 52 : 8 }
    private var dueCount: Int { capacityProtocols.filter(\.isCtaEnabled).count }
    private var activeCount: Int {
        let chunks = activeCapacityCountText.replacingOccurrences(of: " ", with: "").split(separator: "/")
        return Int(chunks.first ?? "0") ?? 0
    }
    private var totalCount: Int {
        let chunks = activeCapacityCountText.replacingOccurrences(of: " ", with: "").split(separator: "/")
        return max(1, Int(chunks.last ?? "1") ?? 1)
    }
    private var directiveTitle: String {
        let protocols = max(dueCount, pendingCount)
        if protocols <= 0 {
            return "SYSTEM STABLE. MAINTAIN PROTOCOL DISCIPLINE"
        }
        let label = protocols == 1 ? "PROTOCOL" : "PROTOCOLS"
        return "EXECUTE \(protocols) \(label) TO STABILIZE SYSTEM"
    }
    private var systemStateText: String {
        capacityStatusText.uppercased() == "STABLE" ? "SYSTEM STATE: STABLE" : "SYSTEM STATE: UNSTABLE"
    }
    private var systemStateColor: Color {
        capacityStatusText.uppercased() == "STABLE" ? primary : Color(hex: "FBBF24")
    }
    private var effectiveMotionSessionID: String {
        motionSessionID.isEmpty ? "launch-pending" : motionSessionID
    }
    private var didAnimateThisSession: Bool {
        didAnimateCockpitPhase1SessionID == effectiveMotionSessionID
    }

    var body: some View {
        ZStack {
            screenBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if showEmbeddedHeader {
                        embeddedHeader
                    }

                    systemStateBadge
                        .padding(.top, 8)

                    ringModule
                        .padding(.top, 32)
                        .padding(.bottom, 10)
                        .opacity(showReliabilityModule ? 1 : 0)
                        .offset(y: showReliabilityModule ? 0 : 12)

                    weeklyStrip
                        .padding(.top, 18)
                        .opacity(showWeeklyStrip ? 1 : 0)
                        .offset(y: showWeeklyStrip ? 0 : 12)

                    activeProtocolsSection
                        .padding(.top, 22)
                        .opacity(showActiveSection ? 1 : 0)
                        .offset(y: showActiveSection ? 0 : 14)

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, topPadding)
            }
        }
        .onAppear {
            runEntranceIfNeeded()
            if didAnimateThisSession || reduceMotion {
                animatedReliabilityValue = Double(max(0, min(reliabilityScore, 100)))
            } else {
                animateReliabilityValue(to: reliabilityScore)
            }
        }
        .onChange(of: reliabilityScore) { newValue in
            animateReliabilityValue(to: newValue)
        }
    }
}

private extension CockpitModernView {
    @ViewBuilder
    var screenBackground: some View {
        if style == .light {
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
        } else {
            LinearGradient(
                colors: [bgTop, bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    var embeddedHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("NEURAL INTERFACE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.8)
                    .foregroundColor(textSecondary)
                Text("TACTICAL COCKPIT")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textMain)
            }
            Spacer()
        }
    }

    var systemStateBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(systemStateColor)
                .frame(width: 7, height: 7)
                .shadow(color: systemStateColor.opacity(0.5), radius: 6, x: 0, y: 0)
            Text(systemStateText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(systemStateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(systemStateColor.opacity(style == .dark ? 0.14 : 0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(systemStateColor.opacity(0.34), lineWidth: 1)
        )
    }

    var ringModule: some View {
        ZStack {
            Circle()
                .stroke(ringTrack, lineWidth: ringStroke)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(animatedReliabilityValue, 100))) / 100)
                .stroke(primary, style: StrokeStyle(lineWidth: ringStroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
                .shadow(color: primary.opacity(style == .dark ? 0.6 : 0.35), radius: 12, x: 0, y: 0)

            VStack(spacing: 8) {
                Text("RELIABILITY SCORE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(2.0)
                    .foregroundColor(textSecondary)
                Text("\(Int(animatedReliabilityValue.rounded()))%")
                    .font(.system(size: 58, weight: .black))
                    .foregroundColor(ringValueTextColor)
                    .contentTransition(.numericText())
                    .shadow(color: primary.opacity(style == .dark ? 0.4 : 0.15), radius: 8, x: 0, y: 0)
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("+2.4%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(ringMetaTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(primary.opacity(style == .dark ? 0.14 : 0.12)))
                .overlay(
                    Capsule()
                        .stroke(primary.opacity(0.32), lineWidth: 1)
                )
            }

            Button(action: onStreakTap) {
                streakBadge
            }
            .buttonStyle(CockpitPressScaleButtonStyle())
            .offset(x: 98, y: -68)
        }
    }

    var streakBadge: some View {
        VStack(spacing: 2) {
            Text("STREAK")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(textSecondary)
            Text("\(streakDays)")
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(textMain)
            Text("DAYS")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(streakAccentColor)
        }
        .frame(width: 68, height: 84)
        .background(glassCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var weeklyStrip: some View {
        Button(action: onWeeklyActivityTap) {
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let hasCompleted = index < weeklyCompletionByDay.count && weeklyCompletionByDay[index] > 0
                    let isToday = index == currentWeekdayIndex
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(hasCompleted ? subtleCard : glassCard)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isToday ? weeklyAccentColor : (style == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)),
                                            lineWidth: isToday ? 2 : 1
                                        )
                                )
                                .frame(width: 36, height: 36)

                            if isToday {
                                Text("\(currentDayOfMonth)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(weeklyAccentColor)
                            } else if hasCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(weeklyAccentColor)
                            }
                        }
                        Text(dayLabel(for: index))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(isToday ? weeklyAccentColor : textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .contentShape(Rectangle())
        .buttonStyle(CockpitPressScaleButtonStyle())
    }

    var activeProtocolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACTIVE PROTOCOLS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(2.1)
                .foregroundColor(primary)

            Button(action: onCapacityTap) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capacity \(activeCapacityCountText.replacingOccurrences(of: " ", with: ""))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textMain)
                        Text(directiveTitle)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1.1)
                            .foregroundColor(textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 10)

                    HStack(spacing: 6) {
                        ForEach(0..<totalCount, id: \.self) { index in
                            Capsule(style: .continuous)
                                .fill(index < activeCount ? primary : (style == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.08)))
                                .frame(width: 22, height: 8)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(
                                            index < activeCount
                                                ? primary.opacity(0.3)
                                                : (style == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: index < activeCount ? primary.opacity(0.3) : .clear, radius: 5, x: 0, y: 0)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(glassCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(glassStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(CockpitPressScaleButtonStyle())

            VStack(spacing: 10) {
                ForEach(Array(capacityProtocols.prefix(3).enumerated()), id: \.element.id) { index, task in
                    protocolRow(task)
                        .opacity(revealedProtocolRows > index ? 1 : 0)
                        .offset(y: revealedProtocolRows > index ? 0 : 10)
                }
            }
        }
    }

    func protocolRow(_ task: TodayTask) -> some View {
        HStack(spacing: 12) {
            Button {
                if task.isCtaEnabled {
                    onProtocolComplete(task.nnId)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(style == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.18), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(task.isCtaEnabled ? Color.clear : primary.opacity(0.2))
                        )
                    if !task.isCtaEnabled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(primary)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textMain)
                Text(task.subtitle.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(textSecondary)
            }

            Spacer()

            Image(systemName: ProtocolIconCatalog.resolvedSymbolName(task.iconSystemName, fallback: "scope"))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(primary.opacity(0.72))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(glassCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            onProtocolTap(task.nnId)
        }
    }

    func runEntranceIfNeeded() {
        guard hasStartedEntrance == false else { return }
        hasStartedEntrance = true

        if didAnimateThisSession || reduceMotion {
            showReliabilityModule = true
            showWeeklyStrip = true
            showActiveSection = true
            revealedProtocolRows = 3
            didAnimateCockpitPhase1SessionID = effectiveMotionSessionID
            return
        }

        showReliabilityModule = false
        showWeeklyStrip = false
        showActiveSection = false
        revealedProtocolRows = 0

        MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
            showReliabilityModule = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                showWeeklyStrip = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                showActiveSection = true
            }
        }

        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + (Double(index) * 0.07)) {
                MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.content) {
                    revealedProtocolRows = max(revealedProtocolRows, index + 1)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            didAnimateCockpitPhase1SessionID = effectiveMotionSessionID
        }
    }

    func animateReliabilityValue(to score: Int) {
        let clamped = Double(max(0, min(score, 100)))
        MotionRuntime.runMotion(
            reduceMotion,
            animation: .easeOut(duration: 0.55)
        ) {
            animatedReliabilityValue = clamped
        }
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

    var currentDayOfMonth: Int {
        DateRules.isoCalendar.component(.day, from: Date())
    }
}

private struct CockpitPressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.08 : 0),
                radius: configuration.isPressed ? 4 : 0,
                x: 0,
                y: configuration.isPressed ? 1 : 0
            )
            .animation(Theme.Animation.micro, value: configuration.isPressed)
    }
}
