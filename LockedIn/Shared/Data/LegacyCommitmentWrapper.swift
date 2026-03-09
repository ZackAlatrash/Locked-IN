import Foundation

@MainActor
final class LegacyCommitmentWrapper: CommitmentActionService {
    private let store: CommitmentSystemStore
    
    init(store: CommitmentSystemStore) {
        self.store = store
    }
    
    func recordCompletionDetailed(for protocolId: UUID, at date: Date) throws -> CompletionWriteOutcome {
        try store.recordCompletionDetailed(for: protocolId, at: date)
    }
    
    func runDailyIntegrityTick(referenceDate: Date) {
        store.runDailyIntegrityTick(referenceDate: referenceDate)
    }
    
    func currentStreakDays(referenceDate: Date) -> Int {
        store.currentStreakDays(referenceDate: referenceDate)
    }
    
    func policyCopy(for error: Error) -> PolicyCopy? {
        store.policyCopy(for: error)
    }
}
