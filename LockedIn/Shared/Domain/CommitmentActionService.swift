import Foundation

@MainActor
protocol CommitmentActionService {
    func recordCompletionDetailed(for protocolId: UUID, at date: Date) throws -> CompletionWriteOutcome
    func runDailyIntegrityTick(referenceDate: Date)
    func currentStreakDays(referenceDate: Date) -> Int
    func policyCopy(for error: Error) -> PolicyCopy?
}
