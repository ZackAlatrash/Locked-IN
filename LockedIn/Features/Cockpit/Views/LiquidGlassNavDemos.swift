import SwiftUI

struct SystemLiquidGlassNavDemoView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var mode: DemoContentMode = .list

    private let navSpace = "system-liquid-glass-space"

    var body: some View {
        contentBody
        .modifier(
            LiquidGlassNavBarStyle(
                title: "System Glass",
                titleDisplayMode: .large,
                scrollOffset: scrollOffset,
                leading: { EmptyView() },
                trailing: {
                    Button {
                        // demo action
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("More options")
                }
            )
        )
    }

    @ViewBuilder
    var contentBody: some View {
        if mode == .list {
            listContent
        } else {
            scrollContent
        }
    }

    var listContent: some View {
        List {
            Section {
                contentModePicker
            }

            ForEach(0..<30, id: \.self) { index in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protocol \(index + 1)")
                        .font(.headline)
                    Text("System-style Liquid Glass nav bar demo row.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }

    var scrollContent: some View {
        ScrollView {
            LiquidGlassScrollOffsetReader(coordinateSpaceName: navSpace)
            VStack(spacing: 12) {
                contentModePicker

                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 86)
                        .overlay(
                            Text("Scroll card \(index + 1)")
                                .font(.headline)
                        )
                }
            }
            .padding()
        }
        .coordinateSpace(name: navSpace)
        .onPreferenceChange(LiquidGlassScrollOffsetPreferenceKey.self) { scrollOffset = $0 }
    }

    var contentModePicker: some View {
        Picker("Content", selection: $mode) {
            Text("List").tag(DemoContentMode.list)
            Text("ScrollView").tag(DemoContentMode.scroll)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Content type")
    }
}

struct FloatingLiquidGlassNavDemoView: View {
    @State private var scrollOffset: CGFloat = 0
    private let navSpace = "floating-liquid-glass-space"

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LiquidGlassScrollOffsetReader(coordinateSpaceName: navSpace)
                VStack(spacing: 12) {
                    Color.clear.frame(height: 112)

                    ForEach(0..<28, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.14))
                            .frame(height: 100)
                            .overlay(
                                HStack {
                                    Image(systemName: "bolt.fill")
                                    Text("Floating Header Item \(index + 1)")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: navSpace)
            .onPreferenceChange(LiquidGlassScrollOffsetPreferenceKey.self) { scrollOffset = $0 }

            floatingHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension FloatingLiquidGlassNavDemoView {
    var floatingHeader: some View {
        let collapsed = scrollOffset > 24
        let titleSize: CGFloat = collapsed ? 18 : 28
        let subtitleOpacity = max(0, min(1, 1 - (scrollOffset / 24)))
        let separatorOpacity = collapsed ? 1.0 : 0.0

        return VStack(spacing: 0) {
            FloatingLiquidGlassSurface(cornerRadius: 22) {
                HStack(spacing: 12) {
                    Text("Cockpit")
                        .font(.system(size: titleSize, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Button {
                        // demo action
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Notifications")

                    Button {
                        // demo action
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20, weight: .regular))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Profile")
                }
                .overlay(alignment: .bottomLeading) {
                    Text("Wednesday, Sep 24")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(subtitleOpacity)
                        .offset(y: 22)
                }
                .animation(.easeInOut(duration: 0.18), value: collapsed)
            }
            .overlay(alignment: Alignment.bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: 0.5)
                    .opacity(separatorOpacity)
            }
        }
    }
}

private enum DemoContentMode: Hashable {
    case list
    case scroll
}

struct LiquidGlassNavDemosRootView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("System Liquid Glass Nav Demo") {
                    SystemLiquidGlassNavDemoView()
                }
                NavigationLink("Floating Liquid Glass Nav Demo") {
                    FloatingLiquidGlassNavDemoView()
                }
            }
            .navigationTitle("Liquid Glass Demos")
        }
    }
}
