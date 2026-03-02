import Foundation

final class InMemoryCommitmentSystemRepository: CommitmentSystemRepository {
    private var storedSystem: CommitmentSystem

    init(initialSystem: CommitmentSystem = CommitmentSystem(nonNegotiables: [], createdAt: Date())) {
        self.storedSystem = initialSystem
    }

    func load() throws -> CommitmentSystem {
        storedSystem
    }

    func save(_ system: CommitmentSystem) throws {
        storedSystem = system
    }
}
