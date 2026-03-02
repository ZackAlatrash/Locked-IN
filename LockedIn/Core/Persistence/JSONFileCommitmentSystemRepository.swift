import Foundation

enum JSONCommitmentSystemRepositoryError: Error {
    case fileNotFound
    case loadFailed(Error)
    case saveFailed(Error)
    case decodeFailed(Error)
}

final class JSONFileCommitmentSystemRepository: CommitmentSystemRepository {
    private let fileManager: FileManager
    private let fileName: String
    private let baseDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        fileName: String = "commitment_system.json",
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileName = fileName
        self.baseDirectoryURL = baseDirectoryURL
    }

    var fileURL: URL {
        (try? resolvedFileURL())
            ?? fileManager.temporaryDirectory.appendingPathComponent(fileName)
    }

    func load() throws -> CommitmentSystem {
        let url = try resolvedFileURL()

        if fileManager.fileExists(atPath: url.path) == false {
            let defaultSystem = CommitmentSystem(nonNegotiables: [], createdAt: Date())
            try save(defaultSystem)
            return defaultSystem
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONCommitmentSystemRepositoryError.loadFailed(error)
        }

        do {
            return try makeDecoder().decode(CommitmentSystem.self, from: data)
        } catch {
            throw JSONCommitmentSystemRepositoryError.decodeFailed(error)
        }
    }

    func save(_ system: CommitmentSystem) throws {
        let url = try resolvedFileURL()

        let data: Data
        do {
            data = try makeEncoder().encode(system)
        } catch {
            throw JSONCommitmentSystemRepositoryError.saveFailed(error)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw JSONCommitmentSystemRepositoryError.saveFailed(error)
        }
    }

    private func resolvedFileURL() throws -> URL {
        if let baseDirectoryURL {
            return baseDirectoryURL.appendingPathComponent(fileName)
        }

        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw JSONCommitmentSystemRepositoryError.fileNotFound
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
