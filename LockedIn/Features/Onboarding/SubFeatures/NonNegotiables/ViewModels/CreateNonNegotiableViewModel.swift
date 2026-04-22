import Foundation
import Combine

@MainActor
final class CreateNonNegotiableViewModel: ObservableObject {
    struct GoalOption: Identifiable, Equatable {
        let id: UUID
        let title: String
    }

    enum SubmissionError: LocalizedError, Equatable {
        case validation([String])
        case capacityExceeded
        case invalidDefinition(String)
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case .validation(let messages):
                return messages.joined(separator: "\n")
            case .capacityExceeded:
                return "Capacity reached. You cannot add another non-negotiable right now."
            case .invalidDefinition(let message):
                return message
            case .unknown(let message):
                return message
            }
        }
    }

    @Published var title: String = ""
    @Published var mode: NonNegotiableMode = .session {
        didSet {
            if mode == .daily {
                frequencyPerWeek = 7
                if isUsingCustomDuration == false {
                    selectedDurationMinutes = 15
                }
            } else if isUsingCustomDuration == false && selectedDurationMinutes == 15 {
                selectedDurationMinutes = 60
            }
        }
    }
    @Published var frequencyPerWeek: Int = 4
    @Published var totalLockDays: Int = 28
    @Published var selectedGoalId: UUID
    @Published var selectedIconSystemName: String = NonNegotiableDefinition.defaultIconSystemName(for: .session)
    @Published var preferredExecutionSlot: PreferredExecutionSlot = .none
    @Published var selectedDurationMinutes: Int = 60
    @Published var customDurationText: String = ""
    @Published var isUsingCustomDuration: Bool = false

    @Published var isSubmitting: Bool = false
    @Published var showValidationError: Bool = false
    @Published var fieldValidationMessages: [String] = []
    @Published var submissionErrorMessage: String?

    static let goalOptions: [GoalOption] = [
        GoalOption(id: UUID(uuidString: "A6B8F6E8-8DA8-4DE0-B712-13BF8A4C6611") ?? UUID(), title: "Identity"),
        GoalOption(id: UUID(uuidString: "54BAE0A8-7992-4AA0-9D90-45F75CB1D3EF") ?? UUID(), title: "Performance"),
        GoalOption(id: UUID(uuidString: "DBA8FC85-BAD0-4DE0-907A-FA733A2F8D79") ?? UUID(), title: "Discipline")
    ]
    static let durationPresets: [Int] = [15, 30, 45, 60, 90]
    static let allowedLockDurations: Set<Int> = [14, 28, 60, 90]

    // Backward-compatible properties used by legacy onboarding content.
    @Published var minimumMinutesText: String = ""
    @Published var timeWindowStartHour: Int = 0
    @Published var timeWindowEndHour: Int = 24
    @Published var frequency: NonNegotiableFrequency = .custom

    init(selectedGoalId: UUID? = nil) {
        self.selectedGoalId = selectedGoalId ?? Self.goalOptions.first?.id ?? UUID()
    }

    var isValid: Bool {
        validateMessages().isEmpty
    }

    var frequencyDisplayText: String {
        mode == .daily
            ? "Daily compliance (7 / week)"
            : "\(frequencyPerWeek) session\(frequencyPerWeek == 1 ? "" : "s") / week"
    }

    var selectedGoalTitle: String {
        Self.goalOptions.first(where: { $0.id == selectedGoalId })?.title ?? "Custom"
    }

    // Backward-compatible API used by existing onboarding shell content.
    var action: String {
        get { title }
        set { title = newValue }
    }

    // Backward-compatible API used by existing onboarding shell content.
    var minimum: String {
        get {
            if isUsingCustomDuration {
                return customDurationText
            }
            return "\(selectedDurationMinutes)"
        }
        set { setCustomDurationText(newValue) }
    }

    var effectiveDurationMinutes: Int {
        resolvedDurationMinutes() ?? selectedDurationMinutes
    }

    func updateAction(_ value: String) {
        title = value
        clearErrors()
    }

    func selectIconSystemName(_ iconSystemName: String) {
        selectedIconSystemName = iconSystemName
        clearErrors()
    }

    func updateFrequency(_ value: NonNegotiableFrequency) {
        frequency = value
        switch value {
        case .daily:
            mode = .daily
            frequencyPerWeek = 7
        case .weekdays:
            mode = .session
            frequencyPerWeek = 5
        case .weekends:
            mode = .session
            frequencyPerWeek = 2
        case .custom:
            mode = .session
        }
        clearErrors()
    }

    func updateMinimum(_ value: String) {
        setCustomDurationText(value)
        clearErrors()
    }

    func selectDurationPreset(_ minutes: Int) {
        selectedDurationMinutes = minutes
        minimumMinutesText = "\(minutes)"
        isUsingCustomDuration = false
        clearErrors()
    }

    func enableCustomDuration() {
        isUsingCustomDuration = true
        if customDurationText.isEmpty {
            customDurationText = "\(selectedDurationMinutes)"
            minimumMinutesText = customDurationText
        }
        clearErrors()
    }

    func setCustomDurationText(_ value: String) {
        minimumMinutesText = value
        customDurationText = value
        isUsingCustomDuration = true
        clearErrors()
    }

    func validateForm() -> Bool {
        let messages = validateMessages()
        fieldValidationMessages = messages
        showValidationError = !messages.isEmpty
        submissionErrorMessage = messages.isEmpty ? nil : messages.joined(separator: "\n")
        return messages.isEmpty
    }

    func submit(
        using store: CommitmentSystemStore,
        referenceDate: Date = Date(),
        onSuccess: (UUID) -> Void
    ) {
        guard validateForm() else { return }
        guard let effectiveDuration = resolvedDurationMinutes() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let effectiveFrequency = mode == .daily ? 7 : frequencyPerWeek
            let definition = NonNegotiableDefinition(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                frequencyPerWeek: effectiveFrequency,
                mode: mode,
                goalId: selectedGoalId,
                preferredExecutionSlot: preferredExecutionSlot,
                estimatedDurationMinutes: effectiveDuration,
                iconSystemName: selectedIconSystemName
            )

            let createdProtocolId = try store.createNonNegotiable(
                definition: definition,
                totalLockDays: totalLockDays,
                referenceDate: referenceDate
            )
            clearErrors()
            onSuccess(createdProtocolId)
        } catch {
            let mapped = map(error: error)
            showValidationError = true
            submissionErrorMessage = mapped.errorDescription
            fieldValidationMessages = mapped.errorDescription.map { [$0] } ?? []
        }
    }

    func exportData() -> (action: String, frequency: NonNegotiableFrequency, minimum: String) {
        (title, frequency, minimum)
    }

    private func validateMessages() -> [String] {
        var messages: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Title is required.")
        }

        if mode == .session && !(1...7).contains(frequencyPerWeek) {
            messages.append("Frequency must be between 1 and 7 per week.")
        }

        if Self.allowedLockDurations.contains(totalLockDays) == false {
            messages.append("Lock duration must be 14, 28, 60, or 90 days.")
        }

        guard let duration = resolvedDurationMinutes(),
              NonNegotiableDefinition.isValidEstimatedDuration(duration) else {
            messages.append("Duration must be between 5 and 360 minutes.")
            return messages
        }

        return messages
    }

    private func resolvedDurationMinutes() -> Int? {
        if isUsingCustomDuration {
            return Int(customDurationText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return selectedDurationMinutes
    }

    private func map(error: Error) -> SubmissionError {
        if let storeError = error as? CommitmentStoreError {
            switch storeError {
            case .policyDenied(let reason):
                return .unknown(reason.copy().message)
            case .domain(let wrapped):
                return map(error: wrapped)
            }
        }

        if let systemError = error as? CommitmentSystemError {
            switch systemError {
            case .capacityExceeded:
                return .capacityExceeded
            default:
                return .unknown("Unable to save non-negotiable right now.")
            }
        }

        if let engineError = error as? NonNegotiableEngineError,
           case let .invalidDefinition(reason) = engineError {
            return .invalidDefinition(mapInvalidDefinitionReason(reason))
        }

        return .unknown(error.localizedDescription)
    }

    private func mapInvalidDefinitionReason(_ reason: NonNegotiableDefinitionValidationReason) -> String {
        switch reason {
        case .titleEmpty:
            return "Title is required."
        case .frequencyOutOfRange:
            return "Frequency must be between 1 and 7 per week."
        case .invalidDailyFrequency:
            return "Daily mode requires 7 completions per week."
        case .invalidLockDuration:
            return "Lock duration must be 14, 28, 60, or 90 days."
        case .durationOutOfRange:
            return "Duration must be between 5 and 360 minutes."
        case .iconEmpty:
            return "Please select an icon."
        }
    }

    private func clearErrors() {
        showValidationError = false
        fieldValidationMessages = []
        submissionErrorMessage = nil
    }
}
