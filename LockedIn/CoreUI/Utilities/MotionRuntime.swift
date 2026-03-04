import SwiftUI

enum MotionRuntime {
    static func runMotion(
        _ reduceMotion: Bool,
        animation: Animation,
        _ updates: () -> Void
    ) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation) {
                updates()
            }
        }
    }
}
