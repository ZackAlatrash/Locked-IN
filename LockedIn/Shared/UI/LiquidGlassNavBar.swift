import SwiftUI

// MARK: - Scroll Offset

struct LiquidGlassScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct LiquidGlassScrollOffsetReader: View {
    let coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: LiquidGlassScrollOffsetPreferenceKey.self,
                    value: -proxy.frame(in: .named(coordinateSpaceName)).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Reusable Nav Style

struct LiquidGlassNavBarStyle<Leading: View, Trailing: View>: ViewModifier {
    let title: String
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let scrollOffset: CGFloat
    let backAction: (() -> Void)?
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        scrollOffset: CGFloat = 0,
        backAction: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.titleDisplayMode = titleDisplayMode
        self.scrollOffset = scrollOffset
        self.backAction = backAction
        self.leading = leading
        self.trailing = trailing
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(titleDisplayMode)
            .navigationBarBackButtonHidden(backAction != nil)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        if let backAction {
                            Button(action: backAction) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityLabel("Back")
                        } else {
                            leading()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        trailing()
                    }
                }
            }
            .modifier(LiquidGlassNavBarFallbackStyle(scrollOffset: scrollOffset))
    }
}

private struct LiquidGlassNavBarFallbackStyle: ViewModifier {
    let scrollOffset: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // iOS 26: prefer system native Liquid Glass behavior.
            content
        } else if #available(iOS 16, *) {
            // iOS 16-25 fallback: material + collapsed separator.
            content
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .overlay(alignment: .top) {
                    GeometryReader { proxy in
                        let topInset = proxy.safeAreaInsets.top
                        Rectangle()
                            .fill(Color.primary.opacity(0.16))
                            .frame(height: 0.5)
                            .opacity(scrollOffset > 10 ? 1 : 0)
                            .offset(y: topInset + 44)
                    }
                    .allowsHitTesting(false)
                }
        } else {
            // iOS 15 fallback: separator only.
            content
                .overlay(alignment: .top) {
                    GeometryReader { proxy in
                        let topInset = proxy.safeAreaInsets.top
                        Rectangle()
                            .fill(Color.primary.opacity(0.16))
                            .frame(height: 0.5)
                            .opacity(scrollOffset > 10 ? 1 : 0)
                            .offset(y: topInset + 44)
                    }
                    .allowsHitTesting(false)
                }
        }
    }
}

// MARK: - Floating Surface

struct FloatingLiquidGlassSurface<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = 22,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                content()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.clear)
                            .glassEffect()
                    )
            } else {
                content()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.16),
                                                Color.clear
                                            ]),
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - Integration
/*
 Recommended (system nav bar on iOS 26):
 NavigationStack {
   YourContent()
     .modifier(
       LiquidGlassNavBarStyle(
         title: "Cockpit",
         titleDisplayMode: .large,
         scrollOffset: scrollOffset,
         leading: { EmptyView() },
         trailing: { Button("Edit") {} }
       )
     )
 }

 Optional floating capsule header:
 Overlay your scroll content with FloatingLiquidGlassSurface and drive transforms via
 LiquidGlassScrollOffsetPreferenceKey.
 */
