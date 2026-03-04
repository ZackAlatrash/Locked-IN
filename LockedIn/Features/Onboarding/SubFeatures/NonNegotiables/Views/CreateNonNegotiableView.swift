import SwiftUI
import UIKit

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
    @State private var showingIconPicker = false
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
                    schedulingProfileCard
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
        .sheet(isPresented: $showingIconPicker) {
            ProtocolIconPickerSheet(
                protocolTitle: viewModel.title,
                initialSelection: viewModel.selectedIconSystemName,
                accentColor: cockpitAccentColor
            ) { selected in
                viewModel.selectIconSystemName(selected)
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

                Button {
                    showingIconPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.selectedIconSystemName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(cockpitAccentColor)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(cockpitAccentColor.opacity(0.14))
                            )
                        Text("Protocol Icon")
                            .font(.system(size: 13, weight: .bold))
                        Text(viewModel.selectedIconSystemName)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(subtitleColor)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(subtitleColor.opacity(0.85))
                    }
                    .foregroundColor(headingColor.opacity(0.74))
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 10)
                    .background(softFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)

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

    var schedulingProfileCard: some View {
        roundedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("SCHEDULING PROFILE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(subtitleColor)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Time")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(headingColor)

                    HStack(spacing: 8) {
                        ForEach(PreferredExecutionSlot.allCases, id: \.self) { slot in
                            preferredSlotChip(slot)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated Duration")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(headingColor)

                    HStack(spacing: 8) {
                        ForEach(CreateNonNegotiableViewModel.durationPresets, id: \.self) { preset in
                            durationPresetChip(preset)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            viewModel.enableCustomDuration()
                        } label: {
                            Text("Custom")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.isUsingCustomDuration ? headingColor : subtitleColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(viewModel.isUsingCustomDuration ? cockpitAccentColor.opacity(0.14) : softFillColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(viewModel.isUsingCustomDuration ? cockpitAccentColor : cardStrokeColor, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        TextField(
                            "minutes",
                            text: Binding(
                                get: { viewModel.customDurationText },
                                set: { viewModel.setCustomDurationText($0) }
                            )
                        )
                            .keyboardType(.numberPad)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(headingColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(softFillColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(cardStrokeColor, lineWidth: 1)
                            )
                            .disabled(viewModel.isUsingCustomDuration == false)
                            .opacity(viewModel.isUsingCustomDuration ? 1 : 0.55)
                    }
                }

                Text("Current: \(viewModel.effectiveDurationMinutes)m")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(subtitleColor)
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

    func preferredSlotChip(_ slot: PreferredExecutionSlot) -> some View {
        Button {
            withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                viewModel.preferredExecutionSlot = slot
            }
        } label: {
            Text(slot.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(viewModel.preferredExecutionSlot == slot ? headingColor : subtitleColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(viewModel.preferredExecutionSlot == slot ? cockpitAccentColor.opacity(0.14) : softFillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(viewModel.preferredExecutionSlot == slot ? cockpitAccentColor : cardStrokeColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    func durationPresetChip(_ minutes: Int) -> some View {
        let isSelected = viewModel.isUsingCustomDuration == false && viewModel.selectedDurationMinutes == minutes
        return Button {
            withAnimation(.easeInOut(duration: Theme.Animation.defaultDuration)) {
                viewModel.selectDurationPreset(minutes)
            }
        } label: {
            Text("\(minutes)m")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? headingColor : subtitleColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? cockpitAccentColor.opacity(0.14) : softFillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? cockpitAccentColor : cardStrokeColor, lineWidth: 1)
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

struct ProtocolIconPickerSheet: View {
    let protocolTitle: String
    let initialSelection: String
    let accentColor: Color
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var selectedCategory: ProtocolIconCatalog.Category = .all
    @State private var selectedSymbol: String
    @State private var recentSymbols: [String]

    init(
        protocolTitle: String,
        initialSelection: String,
        accentColor: Color = .cyan,
        onApply: @escaping (String) -> Void
    ) {
        self.protocolTitle = protocolTitle
        self.initialSelection = initialSelection
        self.accentColor = accentColor
        self.onApply = onApply

        let safeSelection = ProtocolIconCatalog.resolvedSymbolName(
            initialSelection,
            fallback: NonNegotiableDefinition.defaultIconSystemName(for: .session, title: protocolTitle)
        )
        _selectedSymbol = State(initialValue: safeSelection)
        _recentSymbols = State(initialValue: ProtocolIconRecentStore.load())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                previewHeader
                searchBar
                recentRow
                categoryRow
                iconGrid
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applySelection()
                    }
                    .fontWeight(.bold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    applySelection()
                } label: {
                    Text("Apply Icon")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var previewHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(colorScheme == .dark ? 0.18 : 0.16))
                    .frame(width: 58, height: 58)
                Image(systemName: selectedSymbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(protocolTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Protocol" : protocolTitle)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                Text(selectedSymbol)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search icons", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if searchText.isEmpty == false {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var recentRow: some View {
        if recentSymbols.isEmpty == false && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentSymbols, id: \.self) { symbol in
                            iconButton(symbol: symbol, compact: true)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 10)
        }
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProtocolIconCatalog.Category.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.title)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedCategory == category ? (colorScheme == .dark ? Color.black : Color.white) : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? accentColor : (colorScheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.06)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    private var iconGrid: some View {
        ScrollView {
            let symbols = ProtocolIconCatalog.filteredSymbols(
                query: searchText,
                category: selectedCategory
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                ForEach(symbols, id: \.self) { symbol in
                    iconButton(symbol: symbol, compact: false)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
    }

    private func iconButton(symbol: String, compact: Bool) -> some View {
        let isSelected = symbol == selectedSymbol
        return Button {
            selectedSymbol = symbol
        } label: {
            Image(systemName: symbol)
                .font(.system(size: compact ? 14 : 18, weight: .bold))
                .foregroundColor(isSelected ? accentColor : (colorScheme == .dark ? .white : Color(hex: "0F172A")))
                .frame(width: compact ? 34 : 52, height: compact ? 34 : 52)
                .background(
                    RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                        .fill(isSelected ? accentColor.opacity(colorScheme == .dark ? 0.22 : 0.16) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 9 : 12, style: .continuous)
                        .stroke(isSelected ? accentColor.opacity(0.85) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func applySelection() {
        let resolved = ProtocolIconCatalog.resolvedSymbolName(
            selectedSymbol,
            fallback: NonNegotiableDefinition.defaultIconSystemName(for: .session, title: protocolTitle)
        )
        ProtocolIconRecentStore.push(symbol: resolved)
        onApply(resolved)
        dismiss()
    }
}

struct ProtocolIconCatalog {
    enum Category: String, CaseIterable, Identifiable {
        case all
        case focus
        case mind
        case fitness
        case health
        case study
        case life
        case tech

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "ALL"
            case .focus: return "FOCUS"
            case .mind: return "MIND"
            case .fitness: return "FITNESS"
            case .health: return "HEALTH"
            case .study: return "STUDY"
            case .life: return "LIFE"
            case .tech: return "TECH"
            }
        }
    }

    private static let variantSuffixes = ["", ".fill", ".circle", ".circle.fill", ".square", ".square.fill"]

    private static let rootsByCategory: [Category: [String]] = [
        .focus: [
            "bolt", "target", "scope", "timer", "stopwatch", "clock", "alarm", "calendar",
            "flag", "eye", "lightbulb", "sparkles", "wand.and.stars", "pencil", "checkmark", "line.3.horizontal.decrease",
            "chart.bar", "chart.line.uptrend.xyaxis", "waveform", "brain", "brain.head.profile", "bell"
        ],
        .mind: [
            "brain", "brain.head.profile", "moon", "sun.max", "star", "sparkles", "figure.mind.and.body",
            "figure.yoga", "book", "quote.bubble", "headphones", "music.note", "leaf", "cloud", "cloud.sun",
            "cloud.moon", "wind", "snowflake", "globe", "globe.americas", "tortoise", "hare"
        ],
        .fitness: [
            "figure.walk", "figure.run", "figure.strengthtraining.traditional", "figure.cooldown", "figure.highintensity.intervaltraining",
            "dumbbell", "flame", "bolt.heart", "bolt", "waveform.path.ecg", "timer", "stopwatch",
            "bicycle", "sportscourt", "figure.flexibility", "drop", "heart"
        ],
        .health: [
            "heart", "cross", "cross.case", "stethoscope", "pills", "bandage", "cross.vial",
            "lungs", "allergens", "drop", "leaf", "bed.double", "fork.knife", "applelogo",
            "sun.max", "moon.zzz", "figure.walk", "waveform.path.ecg"
        ],
        .study: [
            "book", "book.closed", "books.vertical", "graduationcap", "doc.text", "note.text",
            "pencil", "highlighter", "folder", "tray", "bookmark", "tag", "paperclip", "link",
            "magnifyingglass", "globe", "keyboard", "character.book.closed"
        ],
        .life: [
            "house", "cart", "creditcard", "wallet.pass", "bag", "tshirt", "fork.knife", "cup.and.saucer",
            "car", "airplane", "tram", "location", "map", "pin", "person", "person.2", "person.3",
            "phone", "message", "envelope", "gift", "camera", "photo", "film", "music.note"
        ],
        .tech: [
            "desktopcomputer", "laptopcomputer", "ipad", "iphone", "applewatch", "visionpro", "cpu", "memorychip",
            "server.rack", "externaldrive", "wifi", "antenna.radiowaves.left.and.right", "network",
            "terminal", "curlybraces", "hammer", "wrench", "screwdriver", "lock", "key",
            "shield", "bolt.horizontal", "wave.3.right", "app.badge", "gear", "slider.horizontal.3"
        ]
    ]

    private static let fixedSymbols: [String] = [
        "figure.walk.motion", "figure.run.circle", "figure.core.training", "figure.hiking",
        "airplane.departure", "airplane.arrival", "calendar.badge.clock", "calendar.badge.plus",
        "chart.xyaxis.line", "chart.bar.doc.horizontal", "chart.pie", "chart.dots.scatter",
        "book.pages", "book.pages.fill", "brain.filled.head.profile", "waveform.path.badge.plus"
    ]

    private static let keywordAliases: [String: [String]] = [
        "focus": ["target", "scope", "timer", "stopwatch", "bolt"],
        "work": ["briefcase", "doc.text", "calendar", "checkmark"],
        "health": ["heart", "cross", "stethoscope", "pills", "leaf"],
        "fitness": ["figure.run", "dumbbell", "flame", "sportscourt"],
        "mind": ["brain", "figure.mind.and.body", "moon", "sparkles"],
        "sleep": ["moon", "bed.double", "moon.zzz"],
        "study": ["book", "graduationcap", "note.text", "highlighter"],
        "money": ["creditcard", "banknote", "wallet.pass", "cart"],
        "travel": ["airplane", "car", "tram", "map", "location"],
        "tech": ["cpu", "memorychip", "terminal", "wifi", "server.rack"]
    ]

    private static let allAvailableSymbols: [String] = {
        var ordered: [String] = []
        for category in Category.allCases where category != .all {
            ordered.append(contentsOf: symbols(for: category))
        }
        ordered.append(contentsOf: fixedSymbols)
        return dedupAndFilter(ordered)
    }()

    static func symbols(for category: Category) -> [String] {
        if category == .all { return allAvailableSymbols }
        let roots = rootsByCategory[category] ?? []
        var candidates: [String] = []
        for root in roots {
            candidates.append(contentsOf: variantSuffixes.map { "\(root)\($0)" })
        }
        return dedupAndFilter(candidates + fixedSymbols)
    }

    static func filteredSymbols(query: String, category: Category) -> [String] {
        let symbols = symbols(for: category)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.isEmpty == false else { return symbols }

        let aliasMatches = keywordAliases.reduce(into: Set<String>()) { partial, pair in
            if pair.key.contains(trimmed) {
                pair.value.forEach { alias in
                    for symbol in symbols where symbol.contains(alias) {
                        partial.insert(symbol)
                    }
                }
            }
        }

        return symbols.filter { symbol in
            symbol.lowercased().contains(trimmed) || aliasMatches.contains(symbol)
        }
    }

    static func resolvedSymbolName(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty == false, UIImage(systemName: trimmed) != nil {
            return trimmed
        }
        if UIImage(systemName: fallback) != nil {
            return fallback
        }
        return "bolt.fill"
    }

    private static func dedupAndFilter(_ candidates: [String]) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        for symbol in candidates {
            guard seen.insert(symbol).inserted else { continue }
            guard UIImage(systemName: symbol) != nil else { continue }
            output.append(symbol)
        }
        return output
    }
}

private enum ProtocolIconRecentStore {
    private static let key = "recent_protocol_icon_symbols_v1"
    private static let maxCount = 20

    static func load() -> [String] {
        let saved = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return saved.filter { UIImage(systemName: $0) != nil }
    }

    static func push(symbol: String) {
        var current = load().filter { $0 != symbol }
        current.insert(symbol, at: 0)
        if current.count > maxCount {
            current = Array(current.prefix(maxCount))
        }
        UserDefaults.standard.set(current, forKey: key)
    }
}
