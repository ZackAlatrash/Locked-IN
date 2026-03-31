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
    let upcomingProtocols: [UpcomingTask]
    let showEmbeddedHeader: Bool
    let onWeeklyActivityTap: () -> Void
    let onStreakTap: () -> Void
    let onCapacityTap: () -> Void
    let onCreateTap: () -> Void
    let onCheckInTap: () -> Void
    let onProtocolComplete: (UUID) -> Void
    let onProtocolUndo: (UUID) -> Void
    let onProtocolTap: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("phase1MotionSessionID") private var motionSessionID = ""
    @AppStorage("didAnimateCockpitPhase1SessionID") private var didAnimateCockpitPhase1SessionID = ""

    @State private var hasStartedEntrance = false
    @State private var showReliabilityModule = false
    @State private var showWeeklyStrip = false
    @State private var showActiveSection = false
    @State private var revealedProtocolRows = 0
    @State private var pendingUndoTaskId: UUID?
    @State private var pendingUndoResetTask: Task<Void, Never>?
    @State private var animatedReliabilityValue: Double = 0
    @ScaledMetric(relativeTo: .largeTitle) private var reliabilityScoreFontSize: CGFloat = 58
    @ScaledMetric(relativeTo: .title2) private var ringSize: CGFloat = 222
    @ScaledMetric(relativeTo: .headline) private var ringStroke: CGFloat = 14
    @ScaledMetric(relativeTo: .headline) private var streakBadgeWidth: CGFloat = 68
    @ScaledMetric(relativeTo: .headline) private var streakBadgeHeight: CGFloat = 84
    @ScaledMetric(relativeTo: .body) private var weeklyDayCircleSize: CGFloat = 36
    @ScaledMetric(relativeTo: .caption) private var capacityCapsuleWidth: CGFloat = 22
    @ScaledMetric(relativeTo: .caption) private var capacityCapsuleHeight: CGFloat = 8
    @ScaledMetric(relativeTo: .caption) private var pausedBadgeHorizontalPadding: CGFloat = 10
    @ScaledMetric(relativeTo: .caption) private var pausedBadgeVerticalPadding: CGFloat = 6
    @ScaledMetric(relativeTo: .caption) private var pausedBadgeMinHeight: CGFloat = 26

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
        upcomingProtocols: [UpcomingTask],
        showEmbeddedHeader: Bool = true,
        onWeeklyActivityTap: @escaping () -> Void = {},
        onStreakTap: @escaping () -> Void = {},
        onCapacityTap: @escaping () -> Void = {},
        onCreateTap: @escaping () -> Void = {},
        onCheckInTap: @escaping () -> Void = {},
        onProtocolComplete: @escaping (UUID) -> Void = { _ in },
        onProtocolUndo: @escaping (UUID) -> Void = { _ in },
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
        self.upcomingProtocols = upcomingProtocols
        self.showEmbeddedHeader = showEmbeddedHeader
        self.onWeeklyActivityTap = onWeeklyActivityTap
        self.onStreakTap = onStreakTap
        self.onCapacityTap = onCapacityTap
        self.onCreateTap = onCreateTap
        self.onCheckInTap = onCheckInTap
        self.onProtocolComplete = onProtocolComplete
        self.onProtocolUndo = onProtocolUndo
        self.onProtocolTap = onProtocolTap
    }

    private var isRecoveryMode: Bool {
        modeText.uppercased() == "RECOVERY" || capacityStatusText.uppercased() == "RECOVERY"
    }
    private var primary: Color {
        if isRecoveryMode {
            return style == .dark ? Color(hex: "F87171") : Color(hex: "B91C1C")
        }
        return style == .dark ? Color(hex: "00F2FF") : Color(hex: "3B82F6")
    }
    private var bgTop: Color {
        if isRecoveryMode {
            return style == .dark ? Color(hex: "16080A") : Color(hex: "FDF5F5")
        }
        return Color(hex: "1A243D")
    }
    private var bgBottom: Color {
        if isRecoveryMode {
            return style == .dark ? Color(hex: "020203") : Color(hex: "F9EAEA")
        }
        return Color(hex: "020617")
    }
    private var glassCard: Color {
        if isRecoveryMode {
            return style == .dark ? Color(hex: "1B0A0D").opacity(0.56) : Color.white.opacity(0.8)
        }
        return style == .dark ? Color(hex: "0F172A").opacity(0.42) : Color.white.opacity(0.72)
    }
    private var glassStroke: Color {
        if isRecoveryMode {
            return style == .dark ? Color(hex: "F87171").opacity(0.32) : Color(hex: "FCA5A5").opacity(0.72)
        }
        return style == .dark ? Color.white.opacity(0.09) : Color(hex: "B9C7D7").opacity(0.78)
    }
    private var textMain: Color { style == .dark ? .white : Color(hex: "0B1220") }
    private var textSecondary: Color { style == .dark ? Color.white.opacity(0.62) : Color(hex: "4B5563") }
    private var subtleCard: Color { style == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.035) }
    private var ringTrack: Color { style == .dark ? Color.white.opacity(0.08) : Color(hex: "94A3B8").opacity(0.3) }
    private var ringValueTextColor: Color { style == .dark ? primary : Color(hex: "111827") }
    private var ringMetaTextColor: Color { style == .dark ? primary : Color(hex: "374151") }
    private var topPadding: CGFloat { showEmbeddedHeader ? 52 : 8 }
    private var dueCount: Int { capacityProtocols.filter(\.isRequiredToday).count }
    private var activeCount: Int {
        let chunks = activeCapacityCountText.replacingOccurrences(of: " ", with: "").split(separator: "/")
        return Int(chunks.first ?? "0") ?? 0
    }
    private var totalCount: Int {
        let chunks = activeCapacityCountText.replacingOccurrences(of: " ", with: "").split(separator: "/")
        return max(1, Int(chunks.last ?? "1") ?? 1)
    }
    private var directiveTitle: String {
        if isRecoveryMode {
            return "RECOVERY PROTOCOL ACTIVE. REDUCE LOAD AND EXECUTE CRITICAL TASKS"
        }
        let protocols = max(dueCount, pendingCount)
        if protocols <= 0 {
            return "SYSTEM STABLE. MAINTAIN PROTOCOL DISCIPLINE"
        }
        let label = protocols == 1 ? "PROTOCOL" : "PROTOCOLS"
        return "EXECUTE \(protocols) \(label) TO STABILIZE SYSTEM"
    }
    private var systemStateText: String {
        capacityStatusText.uppercased() == "STABLE" ? "SYSTEM STATE: STABLE" : "SYSTEM STATE: RECOVERY"
    }
    private var systemStateColor: Color {
        capacityStatusText.uppercased() == "STABLE" ? primary : Color(hex: "F87171")
    }
    private var systemStateSymbol: String {
        capacityStatusText.uppercased() == "STABLE" ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
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
        .onDisappear {
            clearPendingUndo()
        }
    }
}

private extension CockpitModernView {
    @ViewBuilder
    var screenBackground: some View {
        if style == .light {
            ZStack {
                if isRecoveryMode {
                    Color(hex: "FCF4F4")
                    RadialGradient(
                        colors: [Color(hex: "FCA5A5").opacity(0.42), .clear],
                        center: UnitPoint(x: 0.5, y: -0.1),
                        startRadius: 0,
                        endRadius: 420
                    )
                    RadialGradient(
                        colors: [Color(hex: "FECACA").opacity(0.45), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 420
                    )
                    RadialGradient(
                        colors: [Color(hex: "FCA5A5").opacity(0.34), .clear],
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
                    .font(.caption2.weight(.medium))
                    .tracking(1.8)
                    .foregroundColor(textSecondary)
                Text("TACTICAL COCKPIT")
                    .font(.title3.weight(.bold))
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
            Image(systemName: systemStateSymbol)
                .font(.caption2.weight(.bold))
                .foregroundColor(systemStateColor)
            Text(systemStateText)
                .font(.caption2.weight(.bold))
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
                    .font(.caption2.weight(.medium))
                    .tracking(2.0)
                    .foregroundColor(textSecondary)
                Text("\(Int(animatedReliabilityValue.rounded()))%")
                    .font(.system(size: reliabilityScoreFontSize, weight: .black))
                    .foregroundColor(ringValueTextColor)
                    .contentTransition(.numericText())
                    .shadow(color: primary.opacity(style == .dark ? 0.4 : 0.15), radius: 8, x: 0, y: 0)
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold))
                    Text("+2.4%")
                        .font(.caption2.weight(.bold))
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
                .font(.caption2.weight(.medium))
                .foregroundColor(textSecondary)
            Text("\(streakDays)")
                .font(.title2.weight(.bold))
                .foregroundColor(textMain)
            Text("DAYS")
                .font(.caption2.weight(.bold))
                .foregroundColor(streakAccentColor)
        }
        .frame(width: streakBadgeWidth, height: streakBadgeHeight)
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
                                .frame(width: weeklyDayCircleSize, height: weeklyDayCircleSize)

                            if isToday {
                                Text("\(currentDayOfMonth)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(weeklyAccentColor)
                            } else if hasCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(weeklyAccentColor)
                            }
                        }
                        Text(dayLabel(for: index))
                            .font(.caption2.weight(.medium))
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
            activeProtocolsHeader

            capacitySummaryCard

            checkInInlineCard

            VStack(spacing: 10) {
                ForEach(Array(capacityProtocols.prefix(3).enumerated()), id: \.element.id) { index, task in
                    protocolRow(task)
                        .opacity(revealedProtocolRows > index ? 1 : 0)
                        .offset(y: revealedProtocolRows > index ? 0 : 10)
                }
            }

            if upcomingProtocols.isEmpty == false {
                upcomingPreviewSection
            }
        }
    }

    var capacitySummaryCard: some View {
        Button(action: onCapacityTap) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Capacity \(activeCapacityCountText.replacingOccurrences(of: " ", with: ""))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(textSecondary.opacity(0.92))
                    Text(directiveTitle)
                        .font(.caption2.weight(.medium))
                        .tracking(0.9)
                        .foregroundColor(textSecondary.opacity(0.86))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let recoveryProgressText {
                        Text(recoveryProgressText.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(primary.opacity(0.82))
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    ForEach(0..<totalCount, id: \.self) { index in
                        capacityIndicator(for: index)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(glassCard.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(glassStroke.opacity(0.8), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(CockpitPressScaleButtonStyle())
    }

    func capacityIndicator(for index: Int) -> some View {
        let isActive = index < activeCount
        let fillColor = isActive ? primary.opacity(0.7) : (style == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07))
        let strokeColor = isActive ? primary.opacity(0.24) : (style == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
        let shadowColor = isActive ? primary.opacity(0.14) : Color.clear
        let width = capacityCapsuleWidth - 2
        let height = max(6, capacityCapsuleHeight - 2)

        return Capsule(style: .continuous)
            .fill(fillColor)
            .frame(width: width, height: height)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 2, x: 0, y: 0)
    }

    var upcomingPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UP NEXT")
                .font(.caption2.weight(.bold))
                .tracking(1.8)
                .foregroundColor(textSecondary.opacity(0.82))

            VStack(spacing: 6) {
                ForEach(upcomingProtocols) { task in
                    HStack(spacing: 8) {
                        Image(systemName: ProtocolIconCatalog.resolvedSymbolName(task.iconSystemName, fallback: "scope"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textSecondary.opacity(0.8))

                        Text(task.title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(textSecondary.opacity(0.92))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(task.timingText.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundColor(textSecondary.opacity(0.75))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(subtleCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(glassStroke.opacity(0.6), lineWidth: 1)
            )
        }
    }

    var activeProtocolsHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                headerTitle
                Spacer(minLength: 0)
                createProtocolButton
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    headerTitle
                    Spacer(minLength: 0)
                    createProtocolButton
                }
            }
        }
    }

    var headerTitle: some View {
        Text("ACTIVE PROTOCOLS")
            .font(.caption2.weight(.bold))
            .tracking(2.1)
            .foregroundColor(primary)
            .lineLimit(1)
    }

    var createProtocolButton: some View {
        Button(action: onCreateTap) {
            Label("ADD PROTOCOL", systemImage: "plus.circle.fill")
                .font(.caption2.weight(.black))
                .tracking(1.1)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(minHeight: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(primary.opacity(style == .dark ? 0.2 : 0.14))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(primary.opacity(0.42), lineWidth: 1)
                )
        }
        .buttonStyle(CockpitPressScaleButtonStyle())
        .accessibilityLabel("Create protocol")
    }

    var checkInButton: some View {
        Button(action: onCheckInTap) {
            Label("CHECK IN", systemImage: "checkmark.seal.fill")
                .font(.caption2.weight(.black))
                .tracking(1.1)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(minHeight: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(primary.opacity(style == .dark ? 0.16 : 0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(primary.opacity(0.36), lineWidth: 1)
                )
        }
        .buttonStyle(CockpitPressScaleButtonStyle())
    }

    var checkInInlineCard: some View {
        let checkInTitle = todayCompleted ? "OPEN CHECK-IN" : "CHECK IN"
        let checkInSubtitle: String = {
            if dueCount > 0 {
                return dueCount == 1 ? "1 protocol still due today" : "\(dueCount) protocols still due today"
            }
            if todayCompleted {
                return "Review today's status"
            }
            return "No pending protocols - open check-in"
        }()

        return Button(action: onCheckInTap) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(primary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(primary.opacity(style == .dark ? 0.16 : 0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(checkInTitle)
                        .font(.caption.weight(.black))
                        .tracking(1.2)
                        .foregroundColor(textMain)
                    Text(checkInSubtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(primary.opacity(0.92))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .background(glassCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(primary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(CockpitPressScaleButtonStyle())
        .accessibilityLabel("Check in")
        .accessibilityHint("Opens the daily check-in flow")
    }

    func protocolRow(_ task: TodayTask) -> some View {
        let paused = task.isPaused
        let isUndoArmed = pendingUndoTaskId == task.nnId
        let canUndo = task.completionVisual != .none && !paused
        let completionTint: Color = {
            if paused {
                return style == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.42)
            }
            if isUndoArmed {
                return Color(hex: "F59E0B")
            }
            switch task.completionVisual {
            case .none:
                return primary
            case .counted:
                return primary
            case .extra:
                return Color(hex: "FDE047")
            }
        }()
        let showCompletionCheck = task.completionVisual != .none

        return HStack(spacing: 4) {
            Button {
                if task.isCtaEnabled {
                    clearPendingUndo()
                    onProtocolComplete(task.nnId)
                } else if canUndo {
                    handleUndoTap(for: task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(style == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.18), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(showCompletionCheck ? completionTint.opacity(0.2) : Color.clear)
                        )
                    if showCompletionCheck {
                        Image(systemName: isUndoArmed ? "arrow.uturn.backward" : "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(completionTint)
                    }
                }
                .frame(width: 22, height: 22)
                .padding(11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onProtocolTap(task.nnId)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(paused ? textSecondary : textMain)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(task.subtitle.uppercased())
                            .font(.caption2.weight(.medium))
                            .tracking(1.2)
                            .foregroundColor(paused ? textSecondary.opacity(0.86) : textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        if isUndoArmed {
                            Text("TAP AGAIN TO UNDO")
                                .font(.caption2.weight(.bold))
                                .tracking(1.2)
                                .foregroundColor(Color(hex: "F59E0B"))
                                .lineLimit(1)
                        }
                    }
                    .layoutPriority(1)

                    Spacer()

                    if paused {
                        Text("PAUSED")
                            .font(.caption.weight(.black))
                            .tracking(0.8)
                            .foregroundColor(textSecondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, pausedBadgeHorizontalPadding)
                            .padding(.vertical, pausedBadgeVerticalPadding)
                            .frame(minHeight: pausedBadgeMinHeight)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(style == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
                            )
                    }

                    Image(systemName: ProtocolIconCatalog.resolvedSymbolName(task.iconSystemName, fallback: "scope"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(paused ? textSecondary : primary.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .padding(.trailing, 14)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .background(glassCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(paused ? 0.72 : 1)
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

    func handleUndoTap(for task: TodayTask) {
        if pendingUndoTaskId == task.nnId {
            clearPendingUndo()
            onProtocolUndo(task.nnId)
            return
        }

        pendingUndoTaskId = task.nnId
        pendingUndoResetTask?.cancel()
        pendingUndoResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard Task.isCancelled == false else { return }
            if pendingUndoTaskId == task.nnId {
                pendingUndoTaskId = nil
            }
        }
    }

    func clearPendingUndo() {
        pendingUndoTaskId = nil
        pendingUndoResetTask?.cancel()
        pendingUndoResetTask = nil
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
        let labels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.985 : 1))
            .shadow(
                color: Color.black.opacity((configuration.isPressed && !reduceMotion) ? 0.08 : 0),
                radius: (configuration.isPressed && !reduceMotion) ? 4 : 0,
                x: 0,
                y: (configuration.isPressed && !reduceMotion) ? 1 : 0
            )
            .animation(reduceMotion ? .none : Theme.Animation.micro, value: configuration.isPressed)
    }
}
