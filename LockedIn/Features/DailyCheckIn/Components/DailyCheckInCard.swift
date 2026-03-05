import SwiftUI

struct DailyCheckInCard<Content: View>: View {
    let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardStroke, lineWidth: 1)
            )
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(hex: "#0B152D").opacity(0.76)
            : Color.white.opacity(0.9)
    }

    private var cardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }
}
