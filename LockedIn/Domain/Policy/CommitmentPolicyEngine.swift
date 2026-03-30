import Foundation

enum PlanPlacementContext: Equatable {
    case manual
    case regulator
}

final class CommitmentPolicyEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func canCreate(
        definition: NonNegotiableDefinition,
        in system: CommitmentSystem,
        at now: Date
    ) -> PolicyDecision {
        _ = definition
        _ = now

        if system.nonNegotiables.contains(where: { $0.state == .recovery }) {
            let cleanDaysRemaining = max(0, 7 - max(system.recoveryCleanDayStreak, 0))
            return .deny(
                .recoveryActive(
                    maxProtocols: system.allowedCapacity,
                    cleanDaysRemaining: cleanDaysRemaining
                )
            )
        }

        let constrainedCount = system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery
        }.count
        if constrainedCount >= system.allowedCapacity {
            return .deny(.capacityExceeded(active: constrainedCount, allowed: system.allowedCapacity))
        }

        if isSystemStable(system) == false {
            return .deny(.systemUnstable)
        }

        return .allow()
    }

    func allowedEditableFields(for nn: NonNegotiable, at now: Date) -> Set<ProtocolField> {
        guard isWithinLock(nn, at: now) else {
            return Set(ProtocolField.allCases)
        }

        return [
            .title,
            .icon,
            .preferredTime,
            .estimatedDuration
        ]
    }

    func canEdit(nn: NonNegotiable, patch: NonNegotiablePatch, at now: Date) -> PolicyDecision {
        if nn.state == .completed || nn.state == .retired {
            return .deny(.protocolCompletedOrRetired)
        }

        guard patch.isEmpty == false else {
            return .allow()
        }

        let allowed = allowedEditableFields(for: nn, at: now)
        for field in patch.touchedFields.sorted(by: fieldOrder) {
            if allowed.contains(field) == false {
                let lockInfo = lockStatus(for: nn, at: now)
                return .deny(
                    .cannotEditFieldDuringLock(
                        field: field,
                        daysRemaining: lockInfo.daysRemaining,
                        endsOn: lockInfo.lockEnd
                    )
                )
            }
        }

        return .allow()
    }

    func canRetire(nn: NonNegotiable, at now: Date) -> PolicyDecision {
        if nn.state == .completed || nn.state == .retired {
            return .deny(.protocolCompletedOrRetired)
        }

        if isWithinLock(nn, at: now) {
            let lockInfo = lockStatus(for: nn, at: now)
            return .deny(
                .cannotRetireDuringLock(
                    daysRemaining: lockInfo.daysRemaining,
                    endsOn: lockInfo.lockEnd
                )
            )
        }

        return .allow()
    }

    func canRemove(nn: NonNegotiable) -> PolicyDecision {
        if nn.state == .completed || nn.state == .retired {
            return .allow()
        }
        return .deny(.cannotRemoveUnlessCompletedOrRetired)
    }

    func canRecordCompletion(nn: NonNegotiable, in system: CommitmentSystem, at now: Date) -> PolicyDecision {
        _ = system
        _ = now

        if nn.state == .suspended {
            return .deny(.protocolSuspended)
        }

        if nn.state == .completed || nn.state == .retired {
            return .deny(.protocolCompletedOrRetired)
        }

        return .allow()
    }

    func canPlaceAllocation(
        nn: NonNegotiable,
        day: Date,
        requiredMinutes: Int,
        availableMinutes: Int,
        at now: Date,
        alreadyScheduledThatDay: Bool,
        context: PlanPlacementContext
    ) -> PolicyDecision {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        let todayStart = DateRules.startOfDay(now, calendar: calendar)

        if dayStart < todayStart {
            return .deny(.cannotPlanIntoPast)
        }

        if alreadyScheduledThatDay {
            return .deny(.protocolAlreadyScheduledThatDay)
        }

        if nn.state == .suspended {
            return .deny(.protocolSuspended)
        }

        if availableMinutes < requiredMinutes {
            return .deny(.notEnoughFreeMinutes(required: requiredMinutes, available: availableMinutes))
        }

        _ = context

        return .allow()
    }
}

private extension CommitmentPolicyEngine {
    struct LockStatus {
        let lockEnd: Date
        let daysRemaining: Int
    }

    func lockStatus(for nn: NonNegotiable, at now: Date) -> LockStatus {
        let lockStart = DateRules.startOfDay(nn.lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(nn.lock.totalLockDays, to: lockStart, calendar: calendar)
        let today = DateRules.startOfDay(now, calendar: calendar)
        let daysRemaining = max(0, calendar.dateComponents([.day], from: today, to: lockEnd).day ?? 0)
        return LockStatus(lockEnd: lockEnd, daysRemaining: daysRemaining)
    }

    func isWithinLock(_ nn: NonNegotiable, at now: Date) -> Bool {
        let status = lockStatus(for: nn, at: now)
        return DateRules.startOfDay(now, calendar: calendar) < status.lockEnd
    }

    func isSystemStable(_ system: CommitmentSystem) -> Bool {
        // Keep policy stability aligned with domain recovery state:
        // once no protocol is in .recovery, the system is considered stable.
        system.nonNegotiables.contains(where: { $0.state == .recovery }) == false
    }

    func fieldOrder(lhs: ProtocolField, rhs: ProtocolField) -> Bool {
        let order: [ProtocolField] = [.mode, .frequency, .lockDuration, .title, .icon, .preferredTime, .estimatedDuration]
        let lhsIndex = order.firstIndex(of: lhs) ?? order.count
        let rhsIndex = order.firstIndex(of: rhs) ?? order.count
        return lhsIndex < rhsIndex
    }
}

private extension ProtocolField {
    static let allCases: [ProtocolField] = [
        .title,
        .icon,
        .preferredTime,
        .estimatedDuration,
        .mode,
        .frequency,
        .lockDuration
    ]
}
