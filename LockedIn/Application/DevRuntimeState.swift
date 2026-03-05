import Foundation
import Combine

@MainActor
final class DevRuntimeState: ObservableObject {
    @Published var reliabilityOverride: Int?
    @Published var forceShowDailyCheckInToken: UUID?

    func clearSessionOverrides() {
        reliabilityOverride = nil
        forceShowDailyCheckInToken = nil
    }

    func requestDailyCheckInPresentation() {
        forceShowDailyCheckInToken = UUID()
    }

    func consumeDailyCheckInPresentationRequest() {
        forceShowDailyCheckInToken = nil
    }
}
