import SwiftUI

struct CockpitWalkthroughOverlay: View {
    let step: WalkthroughStep
    let style: CockpitModernStyle
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
                    Color.black.opacity(step == .walkthroughComplete
                        ? (style == .dark ? 0.82 : 0.65)
                        : (style == .dark ? 0.50 : 0.36)
                    )
                    .allowsHitTesting(false)
                }

                if step == .walkthroughComplete {
                    completionCard
                        .padding(.horizontal, 28)
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    calloutCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 22)
                }
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

    struct OverlayContent {
        let title: String
        let message: String
        let continueTitle: String?
    }

    var overlayContent: OverlayContent {
        switch step {
        case .cockpitIntro:
            return OverlayContent(
                title: "Cockpit",
                message: "Your command center. Reliability score, streak, and today's protocols all live here.",
                continueTitle: "Next"
            )
        case .cockpitReliability:
            return OverlayContent(
                title: "Reliability Score",
                message: "This ring tracks how consistently you follow through. It rises when you complete sessions on time and drops when you miss them.",
                continueTitle: "Next"
            )
        case .cockpitStreak:
            return OverlayContent(
                title: "Weekly Activity",
                message: "Each circle is a day of the current week. A checkmark means at least one session completed that day. The streak badge shows your consecutive active days.",
                continueTitle: "Next"
            )
        case .cockpitProtocols:
            return OverlayContent(
                title: "Today's Protocols",
                message: "Your active commitments for today. Each one has a completion button — tap it after finishing the real-world work to log the session.",
                continueTitle: "Next"
            )
        case .createName:
            return OverlayContent(
                title: "Create Your First Protocol",
                message: "Tap Add Protocol to set up your first commitment.",
                continueTitle: nil
            )
        case .checkInIntro:
            return OverlayContent(
                title: "Complete a Session",
                message: "Tap the checkmark on your protocol once you finish. This logs it to your record and updates your reliability score.",
                continueTitle: nil
            )
        default:
            return OverlayContent(title: "", message: "", continueTitle: "Continue")
        }
    }

    var completionCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(highlightColor)
                .padding(.bottom, 20)

            Text("You're locked in.")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            Text("You know how the system works. Your protocols are live. Miss nothing.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 28)

            Button(action: onContinue) {
                Text("Begin")
                    .font(.system(size: 16, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(highlightColor)
            .accessibilityLabel("Begin using LockedIn")
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 40, x: 0, y: 20)
    }

    var calloutCard: some View {
        let content = overlayContent

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
            Color.black.opacity(style == .dark ? 0.50 : 0.36),
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
            cornerRadius: min(24, max(12, min(frame.width, frame.height) * 0.14))
        )
    }
}
