import Foundation

enum JSONPlanAllocationRepositoryError: Error {
    case fileNotFound
    case loadFailed(Error)
    case saveFailed(Error)
    case decodeFailed(Error)
}

final class JSONFilePlanAllocationRepository: PlanAllocationRepository {
    private let fileManager: FileManager
    private let fileName: String
    private let baseDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        fileName: String = "plan_allocations.json",
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileName = fileName
        self.baseDirectoryURL = baseDirectoryURL
    }

    func load() throws -> [PlanAllocation] {
        let url = try resolvedFileURL()

        if fileManager.fileExists(atPath: url.path) == false {
            try save([])
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw JSONPlanAllocationRepositoryError.loadFailed(error)
        }

        do {
            return try makeDecoder().decode([PlanAllocation].self, from: data)
        } catch {
            throw JSONPlanAllocationRepositoryError.decodeFailed(error)
        }
    }

    func save(_ allocations: [PlanAllocation]) throws {
        let url = try resolvedFileURL()

        let data: Data
        do {
            data = try makeEncoder().encode(allocations)
        } catch {
            throw JSONPlanAllocationRepositoryError.saveFailed(error)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw JSONPlanAllocationRepositoryError.saveFailed(error)
        }
    }

    private func resolvedFileURL() throws -> URL {
        if let baseDirectoryURL {
            return baseDirectoryURL.appendingPathComponent(fileName)
        }

        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw JSONPlanAllocationRepositoryError.fileNotFound
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
