import SwiftUI

struct LogsWalkthroughOverlay: View {
    let step: WalkthroughStep
    let isDarkMode: Bool
    let highlightFrame: CGRect?
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedHighlightFrame: CGRect?
    @State private var spotlightPulse = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if let frame = displayedHighlightFrame {
                    spotlightDimLayer(highlightFrame: frame, in: proxy.size)
                    spotlightOutline(highlightFrame: frame)
                        .allowsHitTesting(false)
                } else {
                    Color.black.opacity(isDarkMode ? 0.50 : 0.36)
                        .allowsHitTesting(false)
                }

                calloutCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 22)
            }
            .animation(reduceMotion ? .none : Theme.Animation.context, value: step)
            .accessibilityAddTraits(.isModal)
            .onAppear {
                updateDisplayedFrame(to: highlightFrame, animated: false)
                if reduceMotion == false {
                    spotlightPulse = true
                }
            }
            .onChange(of: highlightFrame) { _, newFrame in
                updateDisplayedFrame(to: newFrame, animated: true)
            }
        }
    }
}

private extension LogsWalkthroughOverlay {
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

    struct OverlayContent {
        let title: String
        let message: String
        let continueTitle: String
    }

    var overlayContent: OverlayContent {
        switch step {
        case .logsIntro:
            return OverlayContent(
                title: "Diagnostic Log",
                message: "This is your permanent record. Every protocol session you complete or miss gets logged here automatically — nothing to do manually.",
                continueTitle: "Next"
            )
        case .logsMatrix:
            return OverlayContent(
                title: "28-Day Integrity Matrix",
                message: "Each square is a day. Blue = completed, red = violation or miss, yellow = extra-only. Your adherence percentage updates in real time as you log sessions.",
                continueTitle: "Next"
            )
        case .logsHistory:
            return OverlayContent(
                title: "Session History",
                message: "Every event appears here as a timeline entry with timestamps. Use Filter to drill down by event type, protocol, or date range.",
                continueTitle: "Done"
            )
        default:
            return OverlayContent(title: "", message: "", continueTitle: "Continue")
        }
    }

    var calloutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(overlayContent.title)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(overlayContent.message)
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

                Button(action: onContinue) {
                    Text(overlayContent.continueTitle)
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(highlightColor)
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

    var cardFill: Color {
        isDarkMode ? Color(hex: "#0F172A").opacity(0.95) : Color.white.opacity(0.95)
    }

    var cardStroke: Color {
        isDarkMode ? Color.white.opacity(0.20) : Color.black.opacity(0.12)
    }

    var textPrimary: Color {
        isDarkMode ? .white : Color(hex: "#0F172A")
    }

    var textSecondary: Color {
        isDarkMode ? Color.white.opacity(0.82) : Color(hex: "#334155")
    }

    var buttonSecondaryTint: Color {
        isDarkMode ? Color.white.opacity(0.30) : Color.black.opacity(0.18)
    }

    var highlightColor: Color {
        isDarkMode ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    func updateDisplayedFrame(to frame: CGRect?, animated: Bool) {
        guard animated, reduceMotion == false else {
            displayedHighlightFrame = frame
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.16)) {
            displayedHighlightFrame = frame
        }
    }

    func spotlightDimLayer(highlightFrame: CGRect, in size: CGSize) -> some View {
        let metrics = spotlightMetrics(for: highlightFrame)
        return SpotlightCutoutShape(
            canvasSize: size,
            centerX: metrics.center.x,
            centerY: metrics.center.y,
            width: metrics.width,
            height: metrics.height,
            cornerRadius: metrics.cornerRadius
        )
        .fill(
            Color.black.opacity(isDarkMode ? 0.50 : 0.36),
            style: FillStyle(eoFill: true)
        )
        .allowsHitTesting(false)
    }

    func spotlightOutline(highlightFrame: CGRect) -> some View {
        let metrics = spotlightMetrics(for: highlightFrame)
        let shape = SpotlightHoleShape(
            centerX: metrics.center.x,
            centerY: metrics.center.y,
            width: metrics.width,
            height: metrics.height,
            cornerRadius: metrics.cornerRadius
        )
        return ZStack {
            shape
                .stroke(highlightColor.opacity(0.95), lineWidth: 2)

            shape
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

    func spotlightMetrics(for frame: CGRect) -> (center: CGPoint, width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
        (
            center: CGPoint(x: frame.midX, y: frame.midY),
            width: max(frame.width, 44),
            height: max(frame.height, 44),
            cornerRadius: min(26, max(10, min(frame.width, frame.height) * 0.12))
        )
    }
}
