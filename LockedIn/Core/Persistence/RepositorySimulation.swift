import Foundation

func runRepositorySimulation() {
    let repository = JSONFileCommitmentSystemRepository(baseDirectoryURL: FileManager.default.temporaryDirectory)
    let startDate = DateRules.date(year: 2026, month: 1, day: 5, hour: 0)

    let definition = NonNegotiableDefinition(
        title: "Gym",
        frequencyPerWeek: 3,
        mode: .session,
        goalId: UUID()
    )

    let lock = LockConfiguration(startDate: startDate, totalLockDays: 28)
    let firstWindow = Window(
        index: 0,
        startDate: startDate,
        endDate: DateRules.addingDays(14, to: startDate)
    )

    let nonNegotiable = NonNegotiable(
        id: UUID(),
        goalId: definition.goalId,
        definition: definition,
        state: .active,
        lock: lock,
        createdAt: startDate,
        windows: [firstWindow],
        completions: [],
        violations: [],
        lastDailyComplianceCheckedDay: nil
    )

    let system = CommitmentSystem(nonNegotiables: [nonNegotiable], createdAt: startDate)

    do {
        try repository.save(system)
        let loaded = try repository.load()

        print("Repository simulation path: \(repository.fileURL.path)")
        print("Repository simulation equal: \(loaded == system)")
        print("Repository simulation non-negotiables: \(loaded.nonNegotiables.count)")
    } catch {
        print("Repository simulation failed: \(error)")
    }
}
