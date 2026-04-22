import SwiftUI

struct CockpitWalkthroughOverlay: View {
    let step: WalkthroughStep
    let style: CockpitModernStyle
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedHighlightFrame: SpotlightFrame?
    @State private var spotlightPulse = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if let frame = displayedHighlightFrame {
                    spotlightDimLayer(highlightFrame: frame, in: proxy.size)

                    spotlightOutline(highlightFrame: frame)
                        .allowsHitTesting(false)
                } else {
                    Color.black.opacity(style == .dark ? 0.50 : 0.36)
                }

                calloutCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 22)
            }
            .animation(reduceMotion ? .none : Theme.Animation.context, value: step)
            .accessibilityAddTraits(.isModal)
            .onAppear {
                updateDisplayedFrame(for: step, size: proxy.size, animated: false)
                if reduceMotion == false {
                    spotlightPulse = true
                }
            }
            .onChange(of: step) { _, newStep in
                updateDisplayedFrame(for: newStep, size: proxy.size, animated: true)
            }
            .onChange(of: proxy.size) { _, _ in
                updateDisplayedFrame(for: step, size: proxy.size, animated: false)
            }
        }
    }
}

private extension CockpitWalkthroughOverlay {
    struct SpotlightHoleShape: Shape {
        var centerX: CGFloat
        var centerY: CGFloat
        var width: CGFloat
        var height: CGFloat
        var cornerRadius: CGFloat

        var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
            get { AnimatablePair(AnimatablePair(centerX, centerY), AnimatablePair(width, height)) }
            set {
                centerX = newValue.first.first
                centerY = newValue.first.second
                width = newValue.second.first
                height = newValue.second.second
            }
        }

        func path(in rect: CGRect) -> Path {
            let spotlightRect = CGRect(
                x: centerX - width / 2,
                y: centerY - height / 2,
                width: width,
                height: height
            )
            return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .path(in: spotlightRect)
        }
    }

    struct SpotlightCutoutShape: Shape {
        var canvasSize: CGSize
        var centerX: CGFloat
        var centerY: CGFloat
        var width: CGFloat
        var height: CGFloat
        var cornerRadius: CGFloat

        var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
            get { AnimatablePair(AnimatablePair(centerX, centerY), AnimatablePair(width, height)) }
            set {
                centerX = newValue.first.first
                centerY = newValue.first.second
                width = newValue.second.first
                height = newValue.second.second
            }
        }

        func path(in rect: CGRect) -> Path {
            let outer = CGRect(origin: .zero, size: canvasSize)
            let spotlightRect = CGRect(
                x: centerX - width / 2,
                y: centerY - height / 2,
                width: width,
                height: height
            )

            var path = Path()
            path.addRect(outer)
            path.addPath(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .path(in: spotlightRect)
            )
            return path
        }
    }

    struct SpotlightConfig {
        let centerXRatio: CGFloat
        let centerYRatio: CGFloat
        let widthRatio: CGFloat
        let minWidth: CGFloat
        let maxWidth: CGFloat
        let heightRatio: CGFloat
        let minHeight: CGFloat
        let maxHeight: CGFloat
        let cornerRadius: CGFloat

        func frame(in size: CGSize) -> SpotlightFrame {
            SpotlightFrame(
                center: CGPoint(x: size.width * centerXRatio, y: size.height * centerYRatio),
                width: min(max(minWidth, size.width * widthRatio), maxWidth),
                height: min(max(minHeight, size.height * heightRatio), maxHeight),
                cornerRadius: cornerRadius
            )
        }
    }

    struct SpotlightFrame: Equatable {
        let center: CGPoint
        let width: CGFloat
        let height: CGFloat
        let cornerRadius: CGFloat

        var rect: CGRect {
            CGRect(
                x: center.x - width / 2,
                y: center.y - height / 2,
                width: width,
                height: height
            )
        }
    }

    struct OverlayContent {
        let title: String
        let message: String
        let continueTitle: String?
    }

    // Tuning values for spotlight placement.
    // Update these if you want to shift or resize highlight boxes.
    var reliabilitySpotlightConfig: SpotlightConfig {
        SpotlightConfig(
            centerXRatio: 0.50,
            centerYRatio: 0.37,
            widthRatio: 0.85,
            minWidth: 270,
            maxWidth: 340,
            heightRatio: 0.36,
            minHeight: 220,
            maxHeight: 320,
            cornerRadius: 22
        )
    }

    var componentsSpotlightConfig: SpotlightConfig {
        SpotlightConfig(
            centerXRatio: 0.50,
            centerYRatio: 0.81,
            widthRatio: 0.98,
            minWidth: 240,
            maxWidth: 900,
            heightRatio: 0.35,
            minHeight: 220,
            maxHeight: 340,
            cornerRadius: 22
        )
    }

    var streakSpotlightConfig: SpotlightConfig {
        SpotlightConfig(
            centerXRatio: 0.50,
            centerYRatio: 0.59,
            widthRatio: 0.95,
            minWidth: 250,
            maxWidth: 900,
            heightRatio: 0.09,
            minHeight: 72,
            maxHeight: 120,
            cornerRadius: 20
        )
    }

    var addProtocolSpotlightConfig: SpotlightConfig {
        SpotlightConfig(
            centerXRatio: 0.775,
            centerYRatio: 0.673,
            widthRatio: 0.40,
            minWidth: 170,
            maxWidth: 300,
            heightRatio: 0.08,
            minHeight: 56,
            maxHeight: 96,
            cornerRadius: 24
        )
    }

    var checkInSpotlightConfig: SpotlightConfig {
        SpotlightConfig(
            centerXRatio: 0.50,
            centerYRatio: 0.51,
            widthRatio: 0.96,
            minWidth: 250,
            maxWidth: 900,
            heightRatio: 0.17,
            minHeight: 120,
            maxHeight: 220,
            cornerRadius: 18
        )
    }

    var calloutCard: some View {
        let content = overlayContent(for: step)

        return VStack(alignment: .leading, spacing: 14) {
            Text(content.title)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(content.message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(buttonSecondaryTint)
                .accessibilityLabel("Skip walkthrough")

                if let continueTitle = content.continueTitle {
                    Button(action: onContinue) {
                        Text(continueTitle)
                            .font(.system(size: 14, weight: .black))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(highlightColor)
                    .accessibilityLabel(continueTitle)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.32), radius: 20, x: 0, y: 10)
    }

    func overlayContent(for step: WalkthroughStep) -> OverlayContent {
        switch step {
        case .cockpitIntro:
            return OverlayContent(
                title: "Cockpit",
                message: "This is your control center.",
                continueTitle: "Next"
            )
        case .cockpitReliability:
            return OverlayContent(
                title: "Reliability Score",
                message: "This score reflects how consistently you follow through. Higher means more dependable execution.",
                continueTitle: "Next"
            )
        case .cockpitStreak:
            return OverlayContent(
                title: "Streak Tracker",
                message: "These day circles under your score show your weekly streak consistency at a glance.",
                continueTitle: "Next"
            )
        case .cockpitProtocols:
            return OverlayContent(
                title: "Protocols",
                message: "This list is empty right now. Next, we will create your first protocol.",
                continueTitle: "Next"
            )
        case .createName:
            return OverlayContent(
                title: "Create Your First Protocol",
                message: "Tap Add Protocol to create your first commitment.",
                continueTitle: nil
            )
        case .checkInIntro:
            return OverlayContent(
                title: "Check In",
                message: "This is your protocol. From here, you mark it as done. Complete it now.",
                continueTitle: nil
            )
        default:
            return OverlayContent(
                title: "Walkthrough",
                message: "",
                continueTitle: "Continue"
            )
        }
    }

    func updateDisplayedFrame(for step: WalkthroughStep, size: CGSize, animated: Bool) {
        let targetFrame = highlightFrame(for: step, in: size)
        guard animated, reduceMotion == false else {
            displayedHighlightFrame = targetFrame
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.16)) {
            displayedHighlightFrame = targetFrame
        }
    }

    func highlightFrame(for step: WalkthroughStep, in size: CGSize) -> SpotlightFrame? {
        switch step {
        case .cockpitIntro:
            return nil
        case .cockpitReliability:
            return reliabilitySpotlightConfig.frame(in: size)
        case .cockpitStreak:
            return streakSpotlightConfig.frame(in: size)
        case .cockpitProtocols:
            return componentsSpotlightConfig.frame(in: size)
        case .createName:
            return addProtocolSpotlightConfig.frame(in: size)
        case .checkInIntro:
            return checkInSpotlightConfig.frame(in: size)
        default:
            return nil
        }
    }

    var highlightColor: Color {
        style == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    var cardFill: Color {
        style == .dark ? Color(hex: "#0F172A").opacity(0.95) : Color.white.opacity(0.95)
    }

    var cardStroke: Color {
        style == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.12)
    }

    var textPrimary: Color {
        style == .dark ? .white : Color(hex: "#0F172A")
    }

    var textSecondary: Color {
        style == .dark ? Color.white.opacity(0.82) : Color(hex: "#334155")
    }

    var buttonSecondaryTint: Color {
        style == .dark ? Color.white.opacity(0.30) : Color.black.opacity(0.18)
    }

    func spotlightDimLayer(highlightFrame: SpotlightFrame, in size: CGSize) -> some View {
        SpotlightCutoutShape(
            canvasSize: size,
            centerX: highlightFrame.center.x,
            centerY: highlightFrame.center.y,
            width: highlightFrame.width,
            height: highlightFrame.height,
            cornerRadius: highlightFrame.cornerRadius
        )
        .fill(
            Color.black.opacity(style == .dark ? 0.50 : 0.36),
            style: FillStyle(eoFill: true)
        )
        .allowsHitTesting(false)
    }

    func spotlightOutline(highlightFrame: SpotlightFrame) -> some View {
        let spotlightShape = SpotlightHoleShape(
            centerX: highlightFrame.center.x,
            centerY: highlightFrame.center.y,
            width: highlightFrame.width,
            height: highlightFrame.height,
            cornerRadius: highlightFrame.cornerRadius
        )

        return ZStack {
            spotlightShape
                .stroke(highlightColor.opacity(0.95), lineWidth: 2)

            spotlightShape
                .stroke(
                    highlightColor.opacity(spotlightPulse ? 0.34 : 0.20),
                    lineWidth: spotlightPulse ? 6 : 4
                )
                .blur(radius: 2.5)
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: 1.15).repeatForever(autoreverses: true),
                    value: spotlightPulse
                )
        }
    }
}
