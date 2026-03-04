import UIKit

enum Haptics {
    private static let throttleSeconds: TimeInterval = 0.08
    private static var lastFireByKey: [String: TimeInterval] = [:]

    static func selection() {
        fire(key: "selection") {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }

    static func softImpact() {
        fire(key: "softImpact") {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred(intensity: 0.85)
        }
    }

    static func success() {
        fire(key: "success") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }

    static func warning() {
        fire(key: "warning") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
    }
}

private extension Haptics {
    static func fire(key: String, action: () -> Void) {
        let now = CACurrentMediaTime()
        if let last = lastFireByKey[key], now - last < throttleSeconds {
            return
        }
        lastFireByKey[key] = now
        action()
    }
}
