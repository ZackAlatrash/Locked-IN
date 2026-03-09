import SwiftUI

struct ProtocolSchedulingEditorSheet: View {
    let editor: ProtocolSchedulingEditorState
    let errorMessage: String?
    let onSave: (String, PreferredExecutionSlot, Int, String, NonNegotiableMode?, Int?, Int?) -> Bool
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String
    @State private var selectedIconSystemName: String
    @State private var preferredSlot: PreferredExecutionSlot
    @State private var mode: NonNegotiableMode
    @State private var frequencyPerWeek: Int
    @State private var lockDays: Int
    @State private var selectedDurationPreset: Int?
    @State private var customDurationText: String
    @State private var isUsingCustomDuration: Bool
    @State private var localErrorMessage: String?
    @State private var showingIconPicker = false

    private static let durationPresets: [Int] = [15, 30, 45, 60, 90]

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    private var coreRulesLocked: Bool {
        canEdit(.mode) == false &&
        canEdit(.frequency) == false &&
        canEdit(.lockDuration) == false
    }

    init(
        editor: ProtocolSchedulingEditorState,
        errorMessage: String?,
        onSave: @escaping (String, PreferredExecutionSlot, Int, String, NonNegotiableMode?, Int?, Int?) -> Bool,
        onCancel: @escaping () -> Void
    ) {
        self.editor = editor
        self.errorMessage = errorMessage
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: editor.title)
        _selectedIconSystemName = State(
            initialValue: ProtocolIconCatalog.resolvedSymbolName(
                editor.iconSystemName,
                fallback: NonNegotiableDefinition.defaultIconSystemName(for: editor.mode, title: editor.title)
            )
        )
        _preferredSlot = State(initialValue: editor.preferredExecutionSlot)
        _mode = State(initialValue: editor.mode)
        _frequencyPerWeek = State(initialValue: max(1, min(editor.frequencyPerWeek, 7)))
        _lockDays = State(initialValue: editor.lockDays)

        if Self.durationPresets.contains(editor.estimatedDurationMinutes) {
            _selectedDurationPreset = State(initialValue: editor.estimatedDurationMinutes)
            _customDurationText = State(initialValue: "")
            _isUsingCustomDuration = State(initialValue: false)
        } else {
            _selectedDurationPreset = State(initialValue: nil)
            _customDurationText = State(initialValue: "\(editor.estimatedDurationMinutes)")
            _isUsingCustomDuration = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .disabled(canEdit(.title) == false)
                }
                disabledCaption(for: .title)

                Section("Icon") {
                    Button {
                        Haptics.selection()
                        showingIconPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedIconSystemName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(accent)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(accent.opacity(0.15)))
                            Text("Change Protocol Icon")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(canEdit(.icon) == false)
                }
                disabledCaption(for: .icon)

                Section("Core Rules") {
                    Picker("Mode", selection: $mode) {
                        Text("Daily").tag(NonNegotiableMode.daily)
                        Text("Session").tag(NonNegotiableMode.session)
                    }
                    .pickerStyle(.segmented)
                    .tint(coreRulesLocked ? .gray : accent)
                    .disabled(canEdit(.mode) == false)
                    .onChange(of: mode) { newMode in
                        if newMode == .daily {
                            frequencyPerWeek = 7
                        }
                    }

                    Stepper(
                        "\(frequencyPerWeek) / week",
                        value: $frequencyPerWeek,
                        in: 1...7
                    )
                    .disabled(mode == .daily || canEdit(.frequency) == false)

                    HStack(spacing: 8) {
                        ForEach([14, 28], id: \.self) { value in
                            Button("\(value)d") {
                                Haptics.selection()
                                lockDays = value
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(
                                coreRulesLocked
                                    ? .gray.opacity(0.35)
                                    : (lockDays == value ? accent : .gray.opacity(0.3))
                            )
                            .disabled(canEdit(.lockDuration) == false)
                        }
                    }
                }
                .disabled(coreRulesLocked)
                .opacity(coreRulesLocked ? 0.45 : 1.0)
                if mode == .daily {
                    caption("Daily mode is fixed at 7/week.")
                }
                disabledCaption(for: .mode)
                disabledCaption(for: .frequency)
                disabledCaption(for: .lockDuration)

                Section("Preferred Time") {
                    HStack(spacing: 8) {
                        ForEach(PreferredExecutionSlot.allCases, id: \.self) { slot in
                            Button(slot.title) {
                                Haptics.selection()
                                preferredSlot = slot
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(preferredSlot == slot ? accent : .gray.opacity(0.3))
                        }
                    }
                }
                .disabled(canEdit(.preferredTime) == false)
                disabledCaption(for: .preferredTime)

                Section("Duration") {
                    HStack(spacing: 8) {
                        ForEach(Self.durationPresets, id: \.self) { preset in
                            Button("\(preset)m") {
                                Haptics.selection()
                                selectedDurationPreset = preset
                                isUsingCustomDuration = false
                                customDurationText = ""
                                localErrorMessage = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .tint((selectedDurationPreset == preset && isUsingCustomDuration == false) ? accent : .gray.opacity(0.3))
                        }
                    }

                    Toggle("Custom minutes", isOn: $isUsingCustomDuration)
                        .onChange(of: isUsingCustomDuration) { enabled in
                            if enabled {
                                if customDurationText.isEmpty {
                                    customDurationText = "\(selectedDurationPreset ?? editor.estimatedDurationMinutes)"
                                }
                                selectedDurationPreset = nil
                            } else if let parsed = Int(customDurationText), Self.durationPresets.contains(parsed) {
                                selectedDurationPreset = parsed
                            } else {
                                selectedDurationPreset = 60
                            }
                            localErrorMessage = nil
                        }

                    if isUsingCustomDuration {
                        TextField("Minutes (5-360)", text: $customDurationText)
                            .keyboardType(.numberPad)
                    }
                }
                .disabled(canEdit(.estimatedDuration) == false)
                disabledCaption(for: .estimatedDuration)

                if let localErrorMessage {
                    Section {
                        Text(localErrorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                    }
                } else if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .tint(accent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        Haptics.selection()
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let durationMinutes = resolvedDurationMinutes() else {
                            localErrorMessage = "Duration must be between 5 and 360 minutes."
                            Haptics.warning()
                            return
                        }

                        let didSave = onSave(
                            title.trimmingCharacters(in: .whitespacesAndNewlines),
                            preferredSlot,
                            durationMinutes,
                            selectedIconSystemName,
                            canEdit(.mode) ? mode : nil,
                            canEdit(.frequency) ? (mode == .daily ? 7 : frequencyPerWeek) : nil,
                            canEdit(.lockDuration) ? lockDays : nil
                        )
                        if didSave {
                            Haptics.success()
                            dismiss()
                        } else {
                            Haptics.warning()
                            localErrorMessage = errorMessage ?? "Unable to update protocol right now."
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                ProtocolIconPickerSheet(
                    protocolTitle: title,
                    initialSelection: selectedIconSystemName,
                    accentColor: accent
                ) { selected in
                    selectedIconSystemName = selected
                }
            }
        }
    }

    private func resolvedDurationMinutes() -> Int? {
        let value: Int
        if isUsingCustomDuration {
            guard let parsed = Int(customDurationText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return nil
            }
            value = parsed
        } else {
            value = selectedDurationPreset ?? editor.estimatedDurationMinutes
        }

        guard NonNegotiableDefinition.isValidEstimatedDuration(value) else { return nil }
        return value
    }

    private func canEdit(_ field: ProtocolField) -> Bool {
        editor.editableFields.contains(field)
    }

    @ViewBuilder
    private func disabledCaption(for field: ProtocolField) -> some View {
        if canEdit(field) == false {
            caption(
                PolicyReason.cannotEditFieldDuringLock(
                    field: field,
                    daysRemaining: editor.lockDaysRemaining,
                    endsOn: editor.lockEndsOn
                ).copy().message
            )
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
    }
}
