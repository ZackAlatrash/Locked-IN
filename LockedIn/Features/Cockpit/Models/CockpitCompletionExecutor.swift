import Foundation

@MainActor
struct CockpitCompletionExecutionResult: Equatable {
    let toastMessage: String?
}

@MainActor
struct CockpitCompletionExecutor {
    typealias NowProvider = () -> Date

    let commitmentStore: CommitmentSystemStore
    let planStore: PlanStore
    let nowProvider: NowProvider

    func complete(protocolModel: NonNegotiable) throws -> CockpitCompletionExecutionResult {
        let completionDate = nowProvider()
        let outcome = try commitmentStore.recordCompletionDetailed(for: protocolModel.id, at: completionDate)
        let reconciliation = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: protocolModel.definition.mode,
            completionDate: outcome.date,
            completionKind: outcome.kind
        )
        commitmentStore.runDailyIntegrityTick(referenceDate: nowProvider())

        if outcome.kind == .extra {
            if protocolModel.definition.mode == .session {
                return CockpitCompletionExecutionResult(
                    toastMessage: "Weekly target already met. Logged as EXTRA."
                )
            }
            return CockpitCompletionExecutionResult(toastMessage: "Logged as EXTRA.")
        }

        if case .released(let released) = reconciliation {
            return CockpitCompletionExecutionResult(
                toastMessage: Self.releasedToastMessage(
                    protocolTitle: protocolModel.definition.title,
                    completionDate: outcome.date,
                    releasedDay: released.day,
                    slot: released.slot
                )
            )
        }

        return CockpitCompletionExecutionResult(toastMessage: nil)
    }

    static func releasedToastMessage(
        protocolTitle: String,
        completionDate: Date,
        releasedDay: Date,
        slot: PlanSlot
    ) -> String {
        let completionDay = DateRules.startOfDay(completionDate)
        let tomorrow = DateRules.addingDays(1, to: completionDay)
        let releasedDayStart = DateRules.startOfDay(releasedDay)

        if releasedDayStart == tomorrow {
            return "\(protocolTitle) wasn't scheduled today. Tomorrow's \(slot.title) session was removed."
        }

        return "\(protocolTitle) wasn't scheduled today. \(releasedDaySlotLabel(day: releasedDayStart, slot: slot)) was removed."
    }

    static func releasedDaySlotLabel(day: Date, slot: PlanSlot) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return "\(formatter.string(from: day).uppercased()) \(slot.title)"
    }
}
