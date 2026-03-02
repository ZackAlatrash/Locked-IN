import Foundation

enum MainTab: Hashable {
    case cockpit
    case plan
    case logs
}

enum CockpitRoute: Hashable, Identifiable {
    case weeklyActivity
    case streak
    case capacity
    case profile

    var id: Self { self }
}
