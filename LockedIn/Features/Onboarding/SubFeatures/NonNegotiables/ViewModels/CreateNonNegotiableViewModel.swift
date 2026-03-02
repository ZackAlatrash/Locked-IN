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
            }
        }
    }
    @Published var frequencyPerWeek: Int = 4
    @Published var totalLockDays: Int = 28
    @Published var selectedGoalId: UUID

    @Published var isSubmitting: Bool = false
    @Published var showValidationError: Bool = false
    @Published var fieldValidationMessages: [String] = []
    @Published var submissionErrorMessage: String?

    static let goalOptions: [GoalOption] = [
        GoalOption(id: UUID(uuidString: "A6B8F6E8-8DA8-4DE0-B712-13BF8A4C6611") ?? UUID(), title: "Identity"),
        GoalOption(id: UUID(uuidString: "54BAE0A8-7992-4AA0-9D90-45F75CB1D3EF") ?? UUID(), title: "Performance"),
        GoalOption(id: UUID(uuidString: "DBA8FC85-BAD0-4DE0-907A-FA733A2F8D79") ?? UUID(), title: "Discipline")
    ]

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
        get { minimumMinutesText }
        set { minimumMinutesText = newValue }
    }

    func updateAction(_ value: String) {
        title = value
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
        minimumMinutesText = value
        clearErrors()
    }

    func validateForm() -> Bool {
        let messages = validateMessages()
        fieldValidationMessages = messages
        showValidationError = !messages.isEmpty
        submissionErrorMessage = messages.isEmpty ? nil : messages.joined(separator: "\n")
        return messages.isEmpty
    }

    func submit(using store: CommitmentSystemStore, onSuccess: () -> Void) {
        guard validateForm() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let effectiveFrequency = mode == .daily ? 7 : frequencyPerWeek
            let definition = NonNegotiableDefinition(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                frequencyPerWeek: effectiveFrequency,
                mode: mode,
                goalId: selectedGoalId
            )

            try store.createNonNegotiable(definition: definition, totalLockDays: totalLockDays)
            clearErrors()
            onSuccess()
        } catch {
            let mapped = map(error: error)
            showValidationError = true
            submissionErrorMessage = mapped.errorDescription
            fieldValidationMessages = mapped.errorDescription.map { [$0] } ?? []
        }
    }

    func exportData() -> (action: String, frequency: NonNegotiableFrequency, minimum: String) {
        (title, frequency, minimumMinutesText)
    }

    private func validateMessages() -> [String] {
        var messages: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Title is required.")
        }

        if mode == .session && !(1...7).contains(frequencyPerWeek) {
            messages.append("Frequency must be between 1 and 7 per week.")
        }

        if totalLockDays != 14 && totalLockDays != 28 {
            messages.append("Lock duration must be 14 or 28 days.")
        }

        return messages
    }

    private func map(error: Error) -> SubmissionError {
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
            return "Lock duration must be 14 or 28 days."
        }
    }

    private func clearErrors() {
        showValidationError = false
        fieldValidationMessages = []
        submissionErrorMessage = nil
    }
}
