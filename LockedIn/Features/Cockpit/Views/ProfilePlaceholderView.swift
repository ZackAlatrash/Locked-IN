import SwiftUI

struct ProfilePlaceholderView: View {
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.dark.rawValue
    @AppStorage(DailyCheckInPolicy.Keys.hour) private var dailyCheckInHour = 18
    @AppStorage(DailyCheckInPolicy.Keys.minute) private var dailyCheckInMinute = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var commitmentSystemStore: CommitmentSystemStore
    @EnvironmentObject private var planStore: PlanStore
    @EnvironmentObject private var walkthroughController: WalkthroughController
    @State private var showRestartConfirmation = false
#if DEBUG
    @EnvironmentObject private var appClock: AppClock
    @EnvironmentObject private var devRuntime: DevRuntimeState
#endif

    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    private var cardBackground: Color { isDarkMode ? Color(hex: "#1C1C1E") : Color.white }
    private var panelBackground: Color { isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }
    private var textMain: Color { isDarkMode ? Color.white : Color(hex: "101827") }
    private var textSecondary: Color { isDarkMode ? Color.white.opacity(0.72) : Color(hex: "6B7280") }
    private var textMuted: Color { isDarkMode ? Color.white.opacity(0.45) : Color(hex: "9CA3AF") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                profileHeader
                appearanceCard
                dailyCheckInCard
                walkthroughCard
#if DEBUG
                devOptionsRow
#endif

                settingRow(title: "Account", subtitle: "Profile and identity")
                settingRow(title: "Notifications", subtitle: "Alerts and reminders")
                settingRow(title: "Data", subtitle: "Export and backup")
                settingRow(title: "Support", subtitle: "Help center and contact")
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ProfilePlaceholderView {
    var profileHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(textMain)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("LockedIn User")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textMain)
                Text("Profile module placeholder")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textMain)
            Picker(
                "Appearance",
                selection: appearanceModeBinding
            ) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var appearanceModeBinding: Binding<String> {
        Binding(
            get: { appAppearanceModeRaw },
            set: { newValue in
                guard newValue != appAppearanceModeRaw else { return }
                Haptics.selection()
                MotionRuntime.runMotion(reduceMotion, animation: Theme.Animation.context) {
                    appAppearanceModeRaw = newValue
                }
            }
        )
    }

    var dailyCheckInCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Check-In Time")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textMain)

            Text("Auto prompt appears once daily after this time if check-in is still open.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textSecondary)

            DatePicker(
                "Check-In Time",
                selection: dailyCheckInTimeBinding,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var dailyCheckInTimeBinding: Binding<Date> {
        Binding(
            get: {
                let calendar = DateRules.isoCalendar
                let now = Date()
                return calendar.date(
                    bySettingHour: dailyCheckInHour,
                    minute: dailyCheckInMinute,
                    second: 0,
                    of: now
                ) ?? now
            },
            set: { newValue in
                let components = DateRules.isoCalendar.dateComponents([.hour, .minute], from: newValue)
                let nextHour = components.hour ?? dailyCheckInHour
                let nextMinute = components.minute ?? dailyCheckInMinute
                guard nextHour != dailyCheckInHour || nextMinute != dailyCheckInMinute else { return }
                Haptics.selection()
                dailyCheckInHour = nextHour
                dailyCheckInMinute = nextMinute
            }
        )
    }

    var walkthroughCard: some View {
        Button {
            showRestartConfirmation = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Redo Walkthrough")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textMain)
                    Text("Replay the guided tour from the beginning")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textMuted)
            }
            .padding(14)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .alert("Redo Walkthrough?", isPresented: $showRestartConfirmation) {
            Button("Start Tour") {
                commitmentSystemStore.stashAndClearForWalkthrough()
                planStore.stashAndClearForWalkthrough()
                walkthroughController.beginRestart()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your protocols will be hidden during the tour and restored automatically when it's done.")
        }
    }

    func settingRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textMain)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textMuted)
        }
        .padding(14)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

#if DEBUG
    var devOptionsRow: some View {
        NavigationLink {
            DevOptionsView(
                controller: DevOptionsController(
                    commitmentStore: commitmentSystemStore,
                    planStore: planStore,
                    appClock: appClock,
                    devRuntime: devRuntime
                )
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dev Options")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textMain)
                    Text("Debug tools, test seeds, and data reset")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textMuted)
            }
            .padding(14)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
#endif
}
