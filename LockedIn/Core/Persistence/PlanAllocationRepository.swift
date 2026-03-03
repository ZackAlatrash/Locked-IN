import Foundation

protocol PlanAllocationRepository {
    func load() throws -> [PlanAllocation]
    func save(_ allocations: [PlanAllocation]) throws
}

final class InMemoryPlanAllocationRepository: PlanAllocationRepository {
    private var value: [PlanAllocation]

    init(value: [PlanAllocation] = []) {
        self.value = value
    }

    func load() throws -> [PlanAllocation] {
        value
    }

    func save(_ allocations: [PlanAllocation]) throws {
        value = allocations
    }
}
