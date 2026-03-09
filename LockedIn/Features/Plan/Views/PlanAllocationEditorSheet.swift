import SwiftUI

struct PlanAllocationEditorSheet: View {
    let allocation: PlanAllocation
    let weekDays: [PlanDayModel]
    let titleForProtocol: (UUID) -> String
    let onMove: (Date, PlanSlot) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date
    @State private var selectedSlot: PlanSlot

    init(
        allocation: PlanAllocation,
        weekDays: [PlanDayModel],
        titleForProtocol: @escaping (UUID) -> String,
        onMove: @escaping (Date, PlanSlot) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.allocation = allocation
        self.weekDays = weekDays
        self.titleForProtocol = titleForProtocol
        self.onMove = onMove
        self.onRemove = onRemove
        _selectedDay = State(initialValue: allocation.day)
        _selectedSlot = State(initialValue: allocation.slot)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    Text(titleForProtocol(allocation.protocolId))
                        .font(.system(size: 16, weight: .bold))
                }

                Section("Move") {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(weekDays) { day in
                            Text("\(day.weekdayLabel) \(day.dayNumberLabel)").tag(day.date)
                        }
                    }

                    Picker("Slot", selection: $selectedSlot) {
                        ForEach(PlanSlot.allCases) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }

                    Button("Apply Move") {
                        Haptics.success()
                        onMove(selectedDay, selectedSlot)
                        dismiss()
                    }
                }

                Section {
                    Button("Remove Allocation", role: .destructive) {
                        Haptics.success()
                        onRemove()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.selection()
                        dismiss()
                    }
                }
            }
        }
    }
}
