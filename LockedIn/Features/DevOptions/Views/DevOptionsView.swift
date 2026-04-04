#if DEBUG
import SwiftUI

struct DevOptionsView: View {
    @ObservedObject var controller: DevOptionsController

    @EnvironmentObject private var appClock: AppClock
    @EnvironmentObject private var devRuntime: DevRuntimeState
    @Environment(\.colorScheme) private var colorScheme

    @State private var pendingDangerAction: DangerAction?
    @State private var simulatedPickerDate = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                if let status = controller.statusMessage {
                    statusBanner(text: status)
                }

                runtimeSimulationSection
                reliabilitySection
                qaUtilitiesSection
                seedSection
                dataResetSection
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Dev Options")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            simulatedPickerDate = appClock.now
        }
        .onChange(of: appClock.simulatedNow) { _, simulated in
            if let simulated {
                simulatedPickerDate = simulated
            }
        }
        .alert(item: $pendingDangerAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.message),
                primaryButton: .destructive(Text(action.confirmLabel)) {
                    performDangerAction(action)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

private extension DevOptionsView {
    enum DangerAction: String, Identifiable {
        case fullWipe
        case clearProtocols
        case clearPlan
        case resetHints

        var id: String { rawValue }

        var title: String {
            switch self {
            case .fullWipe:
                return "Full Wipe"
            case .clearProtocols:
                return "Clear Protocols"
            case .clearPlan:
                return "Clear Plan"
            case .resetHints:
                return "Reset One-Time Hints"
            }
        }

        var message: String {
            switch self {
            case .fullWipe:
                return "This clears app data and test state. You will need to relaunch for the cleanest fresh-start validation."
            case .clearProtocols:
                return "Remove all protocols and related planning state for this test run?"
            case .clearPlan:
                return "Remove all saved plan allocations for all weeks?"
            case .resetHints:
                return "Reset one-time entrances and board hints so they can replay on next app launch?"
            }
        }

        var confirmLabel: String {
            switch self {
            case .fullWipe:
                return "Wipe"
            case .clearProtocols:
                return "Clear"
            case .clearPlan:
                return "Clear"
            case .resetHints:
                return "Reset"
            }
        }
    }

    var runtimeSimulationSection: some View {
        DevOptionsSectionCard(
            title: "Runtime Simulation",
            subtitle: "Session-only app clock for Cockpit, Plan, Logs, and check-in policy"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Now")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(textMuted)
                    Spacer()
                    Text(Self.dateTimeFormatter.string(from: appClock.now))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(textMain)
                }

                Toggle(isOn: Binding(
                    get: { appClock.isSimulating },
                    set: { enabled in
                        Haptics.selection()
                        if enabled {
                            appClock.setSimulatedNow(simulatedPickerDate)
                        } else {
                            appClock.resetToLive()
                        }
                    }
                )) {
                    Text("Use Simulated Clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textMain)
                }

                DatePicker(
                    "Simulated Time",
                    selection: Binding(
                        get: { simulatedPickerDate },
                        set: { newValue in
                            simulatedPickerDate = newValue
                            if appClock.isSimulating {
                                appClock.setSimulatedNow(newValue)
                            }
                        }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appClock.isSimulating ? 1 : 0.65)

                HStack(spacing: 8) {
                    Button("+1h") {
                        Haptics.selection()
                        appClock.advance(minutes: 60)
                    }
                    .buttonStyle(.bordered)

                    Button("+1d") {
                        Haptics.selection()
                        appClock.advance(minutes: 60 * 24)
                    }
                    .buttonStyle(.bordered)

                    Button("Reset to Live") {
                        Haptics.selection()
                        appClock.resetToLive()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.system(size: 12, weight: .bold))
            }
        }
    }

    var reliabilitySection: some View {
        DevOptionsSectionCard(
            title: "Cockpit Reliability",
            subtitle: "Session-only override for QA screenshots and UI verification"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if let override = devRuntime.reliabilityOverride {
                    HStack {
                        Text("Override: \(override)%")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(textMain)
                        Spacer()
                        Button("Use Live") {
                            Haptics.selection()
                            devRuntime.reliabilityOverride = nil
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 11, weight: .bold))
                    }

                    Slider(value: reliabilityBinding, in: 0...100, step: 1)
                        .tint(colorScheme == .dark ? Color(hex: "22D3EE") : Color(hex: "0EA5E9"))
                } else {
                    HStack {
                        Text("Live calculated reliability")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textMuted)
                        Spacer()
                        Button("Enable Override") {
                            Haptics.selection()
                            devRuntime.reliabilityOverride = 85
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(colorScheme == .dark ? Color(hex: "22D3EE") : Color(hex: "0EA5E9"))
                        .font(.system(size: 11, weight: .bold))
                    }
                }
            }
        }
    }

    var qaUtilitiesSection: some View {
        DevOptionsSectionCard(
            title: "QA Utilities",
            subtitle: "Fast triggers for repeated flow validation"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    Haptics.selection()
                    devRuntime.requestDailyCheckInPresentation()
                } label: {
                    rowButtonLabel("Force Daily Check-In Popup", icon: "sparkles.rectangle.stack")
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.selection()
                    pendingDangerAction = .resetHints
                } label: {
                    rowButtonLabel("Reset one-time hints and entrances", icon: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
        }
    }

    var seedSection: some View {
        DevOptionsSectionCard(
            title: "Seed Scenarios",
            subtitle: "Deterministic protocol/completion/plan presets"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(DevSeedScenario.allCases) { scenario in
                    DevSeedScenarioRow(scenario: scenario) {
                        controller.seed(scenario)
                    }
                    if scenario != DevSeedScenario.allCases.last {
                        Divider()
                            .overlay(borderColor)
                    }
                }
            }
        }
    }

    var dataResetSection: some View {
        DevOptionsSectionCard(
            title: "Data Reset",
            subtitle: "Destructive actions for testing only"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                destructiveButton("Clear Plan Allocations", icon: "calendar.badge.minus") {
                    pendingDangerAction = .clearPlan
                }

                destructiveButton("Clear Protocols", icon: "list.bullet.rectangle.portrait") {
                    pendingDangerAction = .clearProtocols
                }

                destructiveButton("Full Wipe + Relaunch Hint", icon: "trash.fill") {
                    pendingDangerAction = .fullWipe
                }
            }
        }
    }

    func performDangerAction(_ action: DangerAction) {
        Haptics.warning()
        switch action {
        case .fullWipe:
            controller.fullWipeAndReset()
        case .clearProtocols:
            controller.clearProtocolsOnly()
        case .clearPlan:
            controller.clearPlanOnly()
        case .resetHints:
            controller.resetOneTimeHintsAndEntrances()
        }
    }

    func statusBanner(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(hex: "22D3EE") : Color(hex: "0EA5E9"))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textMain)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    func rowButtonLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMain)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textMain)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    func destructiveButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
            }
            .foregroundColor(colorScheme == .dark ? Color(hex: "FCA5A5") : Color(hex: "B91C1C"))
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(colorScheme == .dark ? Color.red.opacity(0.12) : Color.red.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.red.opacity(0.35) : Color.red.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var reliabilityBinding: Binding<Double> {
        Binding(
            get: { Double(devRuntime.reliabilityOverride ?? 85) },
            set: { newValue in
                devRuntime.reliabilityOverride = Int(newValue.rounded())
            }
        )
    }

    var pageBackground: Color {
        colorScheme == .dark ? Color.black : Color(hex: "F2F2F7")
    }

    var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "111827")
    }

    var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color(hex: "6B7280")
    }

    var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE, MMM d • HH:mm"
        return formatter
    }()
}
#endif
