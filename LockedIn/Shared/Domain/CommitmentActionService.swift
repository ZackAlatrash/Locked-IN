import Foundation
import Combine

@MainActor
protocol CommitmentActionService {
    func recordCompletionDetailed(for protocolId: UUID, at date: Date) throws -> CompletionWriteOutcome
    func runDailyIntegrityTick(referenceDate: Date)
    func currentStreakDays(referenceDate: Date) -> Int
    func policyCopy(for error: Error) -> PolicyCopy?
    func recoveryEntryContext(referenceDate: Date) -> CommitmentSystemStore.RecoveryEntryContext?
    func nonNegotiable(id: UUID) -> NonNegotiable?
    func pauseProtocolForRecovery(protocolId: UUID, referenceDate: Date) throws
    func completeRecoveryEntryResolution()
    
    var systemPublisher: AnyPublisher<CommitmentSystem, Never> { get }
    func allowedEditableFields(for protocolId: UUID, referenceDate: Date) -> Set<ProtocolField>
    func editNonNegotiable(id: UUID, patch: NonNegotiablePatch, referenceDate: Date) throws
}
