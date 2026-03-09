import SwiftUI

/// Shared presentational wrapper for profile sheet content.
struct ProfileSheetContainer<Content: View>: View {
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationStack {
            content()
        }
    }
}
