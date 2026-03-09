import SwiftUI

struct ToastPresenter: ViewModifier {
    @Binding var message: String?
    let style: AppAppearanceMode
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(style.cockpitStyle == .dark ? .white : Color(hex: "0F172A"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(style.cockpitStyle == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(style.cockpitStyle == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.14), lineWidth: 1)
                        )
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 2_300_000_000)
                                if self.message == message {
                                    withAnimation {
                                        self.message = nil
                                    }
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, style: AppAppearanceMode) -> some View {
        modifier(ToastPresenter(message: message, style: style))
    }
}
