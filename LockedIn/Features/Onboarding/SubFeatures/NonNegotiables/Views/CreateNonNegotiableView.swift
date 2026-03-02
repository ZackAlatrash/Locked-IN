import SwiftUI

private struct CommitmentPeriodOption: Identifiable {
    let id: Int
    let title: String
    let days: Int
    let isAvailable: Bool
}

@MainActor
struct CreateNonNegotiableView: View {
    @EnvironmentObject private var store: CommitmentSystemStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: CreateNonNegotiableViewModel
    private let accentColorOverride: Color?

    let onSuccess: (() -> Void)?
    let onBack: (() -> Void)?

    init(
        accentColorOverride: Color? = nil,
        onSuccess: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: CreateNonNegotiableViewModel())
        self.accentColorOverride = accentColorOverride
        self.onSuccess = onSuccess
        self.onBack = onBack
    }

    init(
        viewModel: CreateNonNegotiableViewModel,
        accentColorOverride: Color? = nil,
        onSuccess: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.accentColorOverride = accentColorOverride
        self.onSuccess = onSuccess
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.md) {
                    titleContext
                    protocolDetailsCard
                    frequencyCard
                    commitmentPeriodCard
                    systemImpactCard

                    if viewModel.showValidationError, let message = viewModel.submissionErrorMessage {
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isDarkMode ? Color(hex: "FCA5A5") : Color(hex: "B91C1C"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 170)
            }

            bottomCTA
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(backgroundLayer.ignoresSafeArea())
        .navigationTitle("New Protocol")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if let onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(headingColor.opacity(0.78))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(softFillColor))
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Circle()
                    .fill(softFillColor)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(headingColor.opacity(0.45))
                    )
            }
        }
    }
}

private extension CreateNonNegotiableView {
    var isDarkMode: Bool {
        colorScheme == .dark
    }

    var maxProtocolsAllowed: Int {
        3
    }

    var cockpitAccentColor: Color {
        accentColorOverride ?? Color(hex: "#A3FF12")
    }

    var canvasColor: Color {
        isDarkMode ? Color(hex: "050608") : Color(hex: "F1F3F6")
    }

    var cardColor: Color {
        isDarkMode ? Color(hex: "1C1C1E") : Color.white
    }

    var cardStrokeColor: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    var headingColor: Color {
        isDarkMode ? Color.white : Color(hex: "101827")
    }

    var subtitleColor: Color {
        isDarkMode ? Color(hex: "8F97A6") : Color(hex: "6B7280")
    }

    var panelColor: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    var softFillColor: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    var chipBackgroundColor: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }

    var topCanvasColor: Color {
        canvasColor
    }

    var periodOptions: [CommitmentPeriodOption] {
        [
            CommitmentPeriodOption(id: 14, title: "Sprint", days: 14, isAvailable: true),
            CommitmentPeriodOption(id: 28, title: "Habit Formation", days: 28, isAvailable: true),
            CommitmentPeriodOption(id: 60, title: "Lifestyle", days: 60, isAvailable: false),
            CommitmentPeriodOption(id: 90, title: "Mastery", days: 90, isAvailable: false)
        ]
    }

    var trackedProtocols: [NonNegotiable] {
        store.system.nonNegotiables.filter { nn in
            nn.state == .active || nn.state == .recovery || nn.state == .suspended
        }
    }

    var effectiveFrequencyPerWeek: Int {
        viewModel.mode == .daily ? 7 : viewModel.frequencyPerWeek
    }

    var currentWeeklyDemand: Int {
        trackedProtocols.reduce(0) { partial, nn in
            partial + nn.definition.frequencyPerWeek
        }
    }

    var projectedProtocolCount: Int {
        trackedProtocols.count + 1
    }

    var canCreateProtocol: Bool {
        trackedProtocols.count < maxProtocolsAllowed
    }

    var demandIncreasePercent: Int {
        guard currentWeeklyDemand > 0 else { return 100 }
        return Int(round((Double(effectiveFrequencyPerWeek) / Double(currentWeeklyDemand)) * 100))
    }

    var capacityProgress: Double {
        let capacity = max(maxProtocolsAllowed, 1)
        return min(max(Double(projectedProtocolCount) / Double(capacity), 0), 1)
    }

    var currentReliabilityScore: Int {
        reliabilityScore(for: store.system, referenceDate: Date())
    }

    var projectedReliabilityScore: Int {
        let demandPenalty = min(Int(round(Double(effectiveFrequencyPerWeek) * 0.9)), 8)
        let overCapacityCount = max(projectedProtocolCount - maxProtocolsAllowed, 0)
        let capacityPenalty = overCapacityCount * 6
        let modePenalty = viewModel.mode == .daily ? 2 : 0
        let totalPenalty = min(demandPenalty + capacityPenalty + modePenalty, 18)

        return max(0, min(100, currentReliabilityScore - totalPenalty))
    }

    var reliabilityDelta: Int {
        projectedReliabilityScore - currentReliabilityScore
    }

    var scoreInfluenceText: String {
        if reliabilityDelta == 0 {
            return "No projected change"
        }
        if reliabilityDelta < 0 {
            return "-\(abs(reliabilityDelta)) if added"
        }
        return "+\(reliabilityDelta) if added"
    }

    var impactSummaryText: String {
        if currentWeeklyDemand == 0 {
            return "This sets your baseline system demand."
        }
        return "New protocol increases weekly system demand by \(demandIncreasePercent)%."
    }

    var capacitySummaryText: String {
        "Projected active load: \(projectedProtocolCount)/\(maxProtocolsAllowed) protocols."
    }

    var capacityLimitText: String {
        "Maximum of \(maxProtocolsAllowed) active protocols allowed."
    }

    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [topCanvasColor, canvasColor],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(cockpitAccentColor.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 140, y: -250)

            Circle()
                .fill(Color(hex: "38BDF8").opacity(0.07))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: -140, y: 280)
        }
    }

    var titleContext: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NON-NEGOTIABLE")
                .font(.system(size: 12, weight: .bold))
                .tracking(2.4)
                .foregroundColor(cockpitAccentColor)
            Text("Configure your lock and system impact.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(subtitleColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    var protocolDetailsCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("PROTOCOL NAME")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.3)
                        .foregroundColor(subtitleColor)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(cockpitAccentColor)
                }

                TextField("e.g. Deep Work: Monk Mode", text: $viewModel.title)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(headingColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)

                Text("Goal axis: \(viewModel.selectedGoalTitle)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(subtitleColor)

                Menu {
                    ForEach(CreateNonNegotiableViewModel.goalOptions) { option in
                        Button(option.title) {
                            viewModel.selectedGoalId = option.id
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Focus Goal")
                            .font(.system(size: 13, weight: .bold))
                        Text(viewModel.selectedGoalTitle)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(headingColor.opacity(0.74))
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 10)
                    .background(softFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    var frequencyCard: some View {
        roundedCard {
            VStack(spacing: Theme.Spacing.md) {
                Text("FREQUENCY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(subtitleColor)

                VStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        modeChip(title: "Session", mode: .session)
                        modeChip(title: "Daily", mode: .daily)
                        Spacer()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Frequency")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(headingColor)
                            Text("Sessions per week")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(subtitleColor)
                        }
                        Spacer()
                        frequencyControl
                    }
                }
            }
        }
    }

    var frequencyControl: some View {
        HStack(spacing: 8) {
            Button {
                guard viewModel.mode == .session else { return }
                withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                    viewModel.frequencyPerWeek = max(1, viewModel.frequencyPerWeek - 1)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(subtitleColor)
                    .frame(width: 34, height: 34)
                    .background(softFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.mode == .daily)

            Text("\(effectiveFrequencyPerWeek)")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(headingColor)
                .frame(minWidth: 34)

            Button {
                guard viewModel.mode == .session else { return }
                withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                    viewModel.frequencyPerWeek = min(7, viewModel.frequencyPerWeek + 1)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(headingColor)
                    .frame(width: 34, height: 34)
                    .background(cockpitAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.mode == .daily)
            .opacity(viewModel.mode == .daily ? 0.45 : 1)
        }
    }

    var commitmentPeriodCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("COMMITMENT PERIOD")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(subtitleColor)
                    Spacer()
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(subtitleColor.opacity(0.8))
                }

                ForEach(periodOptions) { option in
                    periodOptionRow(option)
                }
            }
        }
    }

    func periodOptionRow(_ option: CommitmentPeriodOption) -> some View {
        let isSelected = option.days == viewModel.totalLockDays

        return Button {
            guard option.isAvailable else { return }
            withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                viewModel.totalLockDays = option.days
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? cockpitAccentColor : subtitleColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(cockpitAccentColor)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(option.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(headingColor)

                Spacer()

                Text("\(option.days) Days")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(option.isAvailable ? subtitleColor : subtitleColor.opacity(0.55))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(option.isAvailable && isSelected ? cockpitAccentColor.opacity(0.12) : softFillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(option.isAvailable && isSelected ? cockpitAccentColor : cardStrokeColor, lineWidth: 1.3)
            )
        }
        .buttonStyle(.plain)
        .disabled(!option.isAvailable)
        .opacity(option.isAvailable ? 1 : 0.58)
    }

    var systemImpactCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .top) {
                    Text("SYSTEM IMPACT")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(subtitleColor)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(projectedReliabilityScore)")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(cockpitAccentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("RELIABILITY SCORE")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(cockpitAccentColor)
                        Text(scoreInfluenceText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(subtitleColor)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(trackedProtocols, id: \.id) { nn in
                            protocolImpactTag(
                                title: nn.definition.title,
                                tint: stateTint(for: nn.state),
                                isNew: false
                            )
                        }

                        protocolImpactTag(
                            title: viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Protocol" : viewModel.title,
                            tint: Color(hex: "F59E0B"),
                            isNew: true
                        )
                    }
                    .padding(.vertical, 2)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "D97706"))
                            .padding(.top, 2)

                        Text(impactSummaryText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(headingColor.opacity(0.82))
                    }

                    Text(capacitySummaryText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(subtitleColor)
                        .padding(.leading, 21)
                }
                .padding(Theme.Spacing.sm)
                .background(panelColor)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(spacing: 8) {
                    HStack {
                        Text("Projected Load")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(subtitleColor)
                        Spacer()
                        Text("\(projectedProtocolCount)/\(maxProtocolsAllowed)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(headingColor)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                            Capsule()
                                .fill(cockpitAccentColor)
                                .frame(width: geo.size.width * capacityProgress)
                        }
                    }
                    .frame(height: 10)
                }

                if !canCreateProtocol {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "F87171"))
                        Text(capacityLimitText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isDarkMode ? Color(hex: "FCA5A5") : Color(hex: "B91C1C"))
                    }
                }
            }
        }
    }

    func protocolImpactTag(
        title: String,
        tint: Color,
        isNew: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(headingColor)
                .lineLimit(1)

            if isNew {
                Text("NEW")
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.7)
                    .foregroundColor(cockpitAccentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(cockpitAccentColor.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(chipBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isNew ? tint.opacity(0.55) : cardStrokeColor, lineWidth: 1)
        )
    }

    func stateTint(for state: NonNegotiableState) -> Color {
        switch state {
        case .recovery:
            return Color(hex: "EF4444")
        case .suspended:
            return Color(hex: "F59E0B")
        default:
            return cockpitAccentColor
        }
    }

    var bottomCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    canvasColor.opacity(0.78),
                    canvasColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 52)

            Button {
                guard canCreateProtocol else { return }
                viewModel.submit(using: store) {
                    onSuccess?()
                    dismiss()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.86))
                    Text(
                        viewModel.isSubmitting
                            ? "LOCKING..."
                            : (canCreateProtocol ? "LOCK PROTOCOL" : "MAX PROTOCOLS REACHED")
                    )
                        .font(.system(size: 22, weight: .black))
                        .tracking(0.7)
                        .foregroundColor(Color.black.opacity(0.90))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(cockpitAccentColor)
                .cornerRadius(Theme.CornerRadius.lg)
                .shadow(
                    color: cockpitAccentColor.opacity(0.35),
                    radius: 14,
                    x: 0,
                    y: 6
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting || !canCreateProtocol)
            .opacity((viewModel.isSubmitting || !canCreateProtocol) ? 0.7 : 1)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 24)
            .background(canvasColor)
        }
    }

    func modeChip(title: String, mode: NonNegotiableMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                viewModel.mode = mode
                if mode == .daily {
                    viewModel.frequencyPerWeek = 7
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(viewModel.mode == mode ? headingColor : subtitleColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(viewModel.mode == mode ? cockpitAccentColor.opacity(0.16) : softFillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(viewModel.mode == mode ? cockpitAccentColor : cardStrokeColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    func roundedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(cardStrokeColor, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 14,
                x: 0,
                y: 5
            )
    }

    func reliabilityScore(for system: CommitmentSystem, referenceDate: Date) -> Int {
        guard !system.nonNegotiables.isEmpty else { return 92 }

        let weekId = DateRules.weekID(for: referenceDate)
        var score = 92

        for nn in system.nonNegotiables {
            let currentWindow = nn.windows.first {
                referenceDate >= $0.startDate && referenceDate < $0.endDate
            }
            let thisWeekCompletions = nn.completions.filter { $0.weekId == weekId }.count
            let currentWindowViolations = nn.violations.filter { violation in
                violation.windowIndex == currentWindow?.index
            }.count

            score -= currentWindowViolations * 16

            if nn.state == .suspended {
                score -= 14
            }
            if nn.state == .recovery {
                score -= 22
            }

            let rewardCap = nn.definition.frequencyPerWeek
            score += min(thisWeekCompletions, rewardCap) * 2
        }

        return min(max(score, 0), 100)
    }

}

struct CreateNonNegotiableView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNonNegotiableView()
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
