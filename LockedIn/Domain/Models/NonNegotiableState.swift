import Foundation

enum NonNegotiableState: String, Codable, Equatable {
    case draft
    case active
    case recovery
    case suspended
    case completed
    case retired
}
