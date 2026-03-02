import Foundation

protocol CommitmentSystemRepository {
    func load() throws -> CommitmentSystem
    func save(_ system: CommitmentSystem) throws
}
