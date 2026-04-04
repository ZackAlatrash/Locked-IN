import SwiftUI

struct FitnessLiquidGlassNavAction: Identifiable, Hashable {
    let id: String
    let symbol: String
    let accessibilityLabel: String
    let isSelected: Bool
    let draggable: Bool
    let action: () -> Void

    init(
        id: String,
        symbol: String,
        accessibilityLabel: String,
        isSelected: Bool = false,
        draggable: Bool = false,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.symbol = symbol
        self.accessibilityLabel = accessibilityLabel
        self.isSelected = isSelected
        self.draggable = draggable
        self.action = action
    }

    static func == (lhs: FitnessLiquidGlassNavAction, rhs: FitnessLiquidGlassNavAction) -> Bool {
        lhs.id == rhs.id
            && lhs.symbol == rhs.symbol
            && lhs.accessibilityLabel == rhs.accessibilityLabel
            && lhs.isSelected == rhs.isSelected
            && lhs.draggable == rhs.draggable
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(symbol)
        hasher.combine(accessibilityLabel)
        hasher.combine(isSelected)
        hasher.combine(draggable)
    }
}

struct FitnessLiquidGlassNavStyle: ViewModifier {
    let title: String
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    let actions: [FitnessLiquidGlassNavAction]
    let leading: AnyView?

    @Namespace private var glassNamespace
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isDragging: Bool = false

    init(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        actions: [FitnessLiquidGlassNavAction] = [],
        leading: AnyView? = nil
    ) {
        self.title = title
        self.titleDisplayMode = titleDisplayMode
        self.actions = actions
        self.leading = leading
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(titleDisplayMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        if let leading {
                            leading
                        } else {
                            EmptyView()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingButtons
                }
            }
            .modifier(FitnessNavBarFallbackBackground())
    }

    @ViewBuilder
    private var trailingButtons: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    navButton(for: action)
                }
            }
        }
    }

    @ViewBuilder
    private func navButton(for action: FitnessLiquidGlassNavAction) -> some View {
        let button = Button(action: action.action) {
            Image(systemName: action.symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(action.accessibilityLabel)

        let glassStyledButton = button
            .buttonStyle(.plain)
            .padding(.horizontal, action.isSelected ? 12 : 10)
            .padding(.vertical, action.isSelected ? 8 : 7)
            .background {
                Capsule(style: .continuous)
                    .fill(action.isSelected ? Color.accentColor.opacity(0.24) : Color.clear)
                    .glassEffect()
            }
            .glassEffectID(action.id, in: glassNamespace)

        if action.draggable {
            glassStyledButton
                .offset(dragOffset)
                .gesture(dragGesture)
        } else {
            glassStyledButton
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    dragOffset = .zero
                }
            }
    }
}

private struct FitnessNavBarFallbackBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

private struct FitnessGlassFallbackButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(
                Capsule(style: .continuous)
                    .fill(prominent ? Color.accentColor : Color.clear)
                    .background {
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.22),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func fitnessLiquidGlassNavStyle(
        title: String,
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .large,
        actions: [FitnessLiquidGlassNavAction] = [],
        leading: AnyView? = nil
    ) -> some View {
        modifier(
            FitnessLiquidGlassNavStyle(
                title: title,
                titleDisplayMode: titleDisplayMode,
                actions: actions,
                leading: leading
            )
        )
    }
}

/*
 How to integrate:
 1) Keep system behavior:
    NavigationStack { YourScrollableContent() }
      .fitnessLiquidGlassNavStyle(
         title: "Summary",
         titleDisplayMode: .large,
         actions: [...]
      )

 2) For best iOS 26 fidelity:
    - Let NavigationStack and .navigationTitle drive collapse behavior.
    - Avoid custom fake nav overlays unless you need a floating header.
 */
