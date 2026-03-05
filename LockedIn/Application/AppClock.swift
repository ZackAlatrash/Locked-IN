import Foundation
import Combine

@MainActor
final class AppClock: ObservableObject {
    @Published private(set) var simulatedNow: Date?

    var now: Date {
        simulatedNow ?? Date()
    }

    var isSimulating: Bool {
        simulatedNow != nil
    }

    func setSimulatedNow(_ date: Date) {
        simulatedNow = date
    }

    func advance(minutes: Int) {
        let base = simulatedNow ?? Date()
        simulatedNow = base.addingTimeInterval(TimeInterval(minutes * 60))
    }

    func resetToLive() {
        simulatedNow = nil
    }
}
