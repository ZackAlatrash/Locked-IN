# Retired, Paused, and Expired Protocol Lifecycle Implementation Plan

## Goal

Complete the P0 lifecycle hardening step:

> Retired, paused, and expired protocol edge cases are handled. The app should not show impossible actions or broken statuses when a protocol changes lifecycle state.

This plan covers protocol states that can become stale or contradictory across domain, plan, logs, cockpit/home, and daily check-in surfaces:

- `.active`
- `.recovery`
- `.suspended`
- `.completed`
- `.retired`

The end state should be:

- Retired protocols cannot be planned, completed, or shown as active work.
- Paused protocols clearly show why they are paused and what the user can do next.
- Expired/completed protocol windows do not create false misses.
- If a protocol retires while paused or during recovery, the UI and plan resolve cleanly.
- Lifecycle state is consistent in Plan, Logs, Cockpit/Home, and Daily Check-In.

## Current Coverage Snapshot

### Already covered

- Domain policy blocks completion for suspended, completed, and retired protocols.
- Domain policy blocks manual plan placement for suspended protocols.
- Plan descriptors only include active, recovery, and suspended protocols.
- Plan allocation normalization removes allocations whose protocol is no longer managed.
- Daily/weekly violation evaluation skips retired, completed, and suspended protocols.
- Weekly evaluation clamps the evaluated week to the lock end, preventing many expired-window false misses.
- Cockpit and Daily Check-In show "Paused during recovery" and disable completion actions.
- Retiring from Cockpit passes `planStore`, so paused allocation statuses are finalized on that UI path.

### Still incomplete

- Plan slot `+` affordances can appear enabled outside walkthrough mode without checking selected protocol validity.
- Paused queue cards only show `PAUSED`; they do not explain why the protocol is paused or what happens next.
- `retireNonNegotiable(..., planStore: nil)` remains possible, so non-UI call sites can leave paused allocations unresolved.
- Logs decide whether an entry is recovery-related from the owner's current state, so historical recovery context can be lost after retirement or completion.
- There is no single repair pass that reconciles stale paused allocations for retired, completed, or missing protocols.
- There is no focused automated coverage for all retired/paused/expired lifecycle cases.

## Target Invariants

Use these invariants as the implementation contract.

### LIF-01: Terminal protocols are never actionable

If a protocol is `.retired` or `.completed`:

- It must not appear in Plan queue.
- It must not appear in current active planning candidates.
- It must not appear in Daily Check-In as work to complete.
- It must not appear in Cockpit today tasks as required work.
- Existing history may remain visible in Logs.
- Existing plan allocations should be finalized or removed from active planning views.

### LIF-02: Suspended protocols are visible but not actionable

If a protocol is `.suspended`:

- It can appear in Cockpit/Home and Daily Check-In as paused context.
- It can appear in Plan queue only as disabled context.
- It must not be selectable for placement.
- It must not be draggable.
- Slot `+` buttons must not appear enabled for it.
- Copy must explain: paused during recovery, completions/planning are blocked, recovery completion resumes or resolves it.

### LIF-03: Recovery protocols are active work with recovery context

If a protocol is `.recovery`:

- It can be completed.
- It can be planned if policy allows it.
- It should show recovery context in Cockpit/Home, Logs, and Daily Check-In.
- It must not be offered as a pause candidate when active-only pause selection is the rule.

### LIF-04: Expired windows do not create new misses

Once a protocol reaches lock end:

- `.active` and `.suspended` protocols should become `.completed` through window advancement when appropriate.
- `.completed` protocols must not get new daily or weekly violations.
- A partial final week should only evaluate dates within the lock interval.
- No UI should show "due today" after lock end.

### LIF-05: Paused allocation statuses must converge

Paused allocations must not remain stuck forever after the protocol is no longer paused.

- If paused protocol is restored to `.active`, future paused allocations become `.active`.
- If paused protocol is `.retired`, `.completed`, or missing, paused allocations become `.skippedDueToRecovery`.
- Past paused allocations become `.skippedDueToRecovery`.
- This repair should run even if retirement happened through a non-UI call site.

## Edge Case Matrix

| ID | Scenario | Expected Behavior | Current Risk | Fix Step |
|---|---|---|---|---|
| LIF-EC-01 | Retired protocol has old active allocations | Allocation is not interactive and does not count as active planned work | `normalizeAllocations` removes missing/unmanaged protocols, but defensive skipped status is clearer for recovery-paused allocations | Step 3 |
| LIF-EC-02 | Retired protocol remains in Plan queue | Must not appear as active queue item | Covered by descriptor filter | Verify |
| LIF-EC-03 | Completed protocol remains in Plan queue | Must not appear as active queue item | Covered by descriptor filter | Verify |
| LIF-EC-04 | Suspended protocol appears in Plan queue | It can appear, but disabled with clear reason and no placement action | Card says only `PAUSED`; selection and slot affordance can still mislead | Steps 1, 2 |
| LIF-EC-05 | Suspended protocol selected, user taps empty slot | Slot should be disabled before tap; no "try then reject" UX | `canPlaceAtSlot` returns true outside walkthrough | Step 1 |
| LIF-EC-06 | Suspended protocol dragged to slot | Drag should be unavailable | Mostly covered by `item.isDisabled`; keep test coverage | Step 6 |
| LIF-EC-07 | Paused allocation shown in Plan board | Non-interactive and labeled `PAUSED` with reason available | Label exists, but reason is not obvious | Step 2 |
| LIF-EC-08 | Retire paused protocol through Cockpit | Paused allocations become skipped immediately | Covered when `planStore` is passed | Verify |
| LIF-EC-09 | Retire paused protocol through non-UI call path | Paused allocations should still become skipped | Store API allows `planStore: nil` | Steps 3, 4 |
| LIF-EC-10 | Recovery exits after paused protocol retired | No zombie paused allocations | Mostly covered by finalization, but needs repair coverage | Steps 3, 6 |
| LIF-EC-11 | Protocol expires while suspended | Should become completed or be resolved consistently; paused allocations should not stay active/paused forever | `advanceWindows` skips suspended protocols in `CommitmentSystemEngine.advanceWindows` because only active/recovery are advanced | Step 5 |
| LIF-EC-12 | Protocol expires while active | Should become completed and stop creating misses | Engine completion path exists | Verify with tests |
| LIF-EC-13 | Protocol expires mid-week | No false weekly miss after lock end; final week uses lock interval only | Mostly covered by `effectiveWeekEnd` | Verify with tests |
| LIF-EC-14 | Daily protocol expires after missed days | Misses only through last lock day; no misses after lock end | Mostly covered by daily evaluation end clamp | Verify with tests |
| LIF-EC-15 | Completed protocol has old violations/completions | Logs show history, not active work | Logs support history | Verify |
| LIF-EC-16 | Historical recovery-related log after protocol retires | Entry should remain recoverable/filterable as recovery-related when event came from recovery/suspended period | Current logic uses current owner state | Step 4 |
| LIF-EC-17 | Capacity/Cockpit detail includes terminal protocols | Detail can show terminal states, but home active counts must exclude them | Mostly covered | Verify |
| LIF-EC-18 | Daily Check-In includes terminal protocols | Should exclude completed/retired protocols | Covered by filter | Verify |

## Implementation Steps

## Step 1 - Gate Plan slot placement by actual placement validation

Priority: P0

Files:

- `LockedIn/Features/Plan/Views/PlanScreen.swift`
- `LockedIn/Features/Plan/ViewModels/PlanViewModel.swift` if helper access is needed

Problem:

`canPlaceAtSlot(day:slot:protocolId:)` returns `true` whenever walkthrough is inactive. This means the visual slot affordance can appear enabled even when the selected protocol is suspended, completed, retired, missing, already capped, or otherwise policy-blocked.

Required change:

- Always validate placement when `protocolId` is non-nil.
- Return `false` when no protocol is selected.
- Keep walkthrough restrictions as an additional layer, not the only layer.
- Use existing `viewModel.validateProtocolPlacement(protocolId:day:slot:)`.

Suggested shape:

```swift
func canPlaceAtSlot(day: Date, slot: PlanSlot, protocolId: UUID?) -> Bool {
    guard let protocolId else { return false }

    if walkthroughController.isActive {
        guard let step = activePlanningWalkthroughStep else {
            return viewModel.validateProtocolPlacement(protocolId: protocolId, day: day, slot: slot).isAllowed
        }
        switch step {
        case .planningSelectSlot:
            guard protocolId == walkthroughProtocolId else { return false }
            guard DateRules.startOfDay(day) == DateRules.startOfDay(appClock.now) else { return false }
        default:
            return false
        }
    }

    return viewModel.validateProtocolPlacement(protocolId: protocolId, day: day, slot: slot).isAllowed
}
```

Acceptance checks:

- Select active protocol with remaining work: valid slots show enabled `+`.
- Select suspended protocol: all slot `+` buttons are disabled or visually unavailable.
- Select protocol already at weekly cap: slot `+` buttons are disabled.
- No protocol selected: slot `+` buttons are disabled.
- Walkthrough still restricts placement to the walkthrough protocol and target day.

## Step 2 - Make paused Plan queue and allocation copy explicit

Priority: P0

Files:

- `LockedIn/Features/Plan/Views/PlanScreen.swift`
- Optional: `LockedIn/Features/Plan/Models/PlanModels.swift`

Problem:

Plan queue cards currently show `PAUSED`, but they do not explain why the protocol is paused or what the user can do next. This does not satisfy the acceptance check "Paused protocols show why they are paused and what the user can do next."

Required change:

- For disabled queue cards, show a second line or compact hint:
  - `Paused during recovery`
  - `Resumes after recovery`
- Add an accessibility label/value for paused queue cards:
  - Label: protocol title
  - Value: `Paused during recovery. Planning and completion are unavailable until recovery ends.`
- For paused/skipped allocations, add accessible reason:
  - `Paused during recovery`
  - `Skipped due to recovery`
- Do not rely on color or opacity alone.

Acceptance checks:

- Paused protocol in queue visibly says why it is paused.
- VoiceOver can identify the paused reason without needing visual color.
- Paused allocation chip is non-interactive and labeled as paused.
- Skipped allocation chip is non-interactive and labeled as skipped due to recovery.

## Step 3 - Add defensive PlanStore repair for stale paused allocations

Priority: P0

Files:

- `LockedIn/Application/PlanStore.swift`

Problem:

Paused allocations can become stale if retirement/completion/removal happens outside the UI path that passes `planStore`.

Required change:

Add a repair pass during `PlanStore.refresh(system:calendarEvents:referenceDate:)`, after protocol descriptors are built and before queue/week models are finalized.

Rules:

- For allocation with `status == .paused`:
  - If protocol is `.active` or `.recovery` and allocation is future/current: keep paused until explicit recovery finalization decides whether to restore.
  - If protocol is `.suspended`: keep paused.
  - If protocol is `.retired`, `.completed`, or missing: set `.skippedDueToRecovery`.
  - If allocation is in the past: set `.skippedDueToRecovery`.
- Persist only if mutations occurred.

Important note:

`buildProtocolDescriptors` intentionally excludes terminal protocols from `protocolsById`. The repair function needs access to `lastSystem.nonNegotiables`, not just `protocolsById`, so it can distinguish missing from terminal.

Suggested helper:

```swift
func repairPausedAllocations(referenceDate: Date) {
    guard let lastSystem else { return }
    let statesById = Dictionary(uniqueKeysWithValues: lastSystem.nonNegotiables.map { ($0.id, $0.state) })
    let today = DateRules.startOfDay(referenceDate, calendar: calendar)
    var didMutate = false

    for index in allAllocations.indices where allAllocations[index].status == .paused {
        let allocationDay = DateRules.startOfDay(allAllocations[index].day, calendar: calendar)
        let state = statesById[allAllocations[index].protocolId]
        let shouldSkip =
            allocationDay < today ||
            state == nil ||
            state?.isTerminal == true

        if shouldSkip {
            allAllocations[index].status = .skippedDueToRecovery
            allAllocations[index].updatedAt = Date()
            didMutate = true
        }
    }

    if didMutate {
        try? repository.save(allAllocations)
    }
}
```

Acceptance checks:

- Paused allocation for retired protocol becomes skipped on Plan refresh.
- Paused allocation for completed protocol becomes skipped on Plan refresh.
- Paused allocation for missing protocol becomes skipped or removed consistently.
- Future paused allocation for suspended protocol remains paused.
- Past paused allocation becomes skipped.

## Step 4 - Make retirement-with-plan-sync the default safe API

Priority: P0

Files:

- `LockedIn/Application/CommitmentSystemStore.swift`
- Call sites in `LockedIn/Features`

Problem:

`retireNonNegotiable(id:referenceDate:planStore:)` accepts `planStore: nil`. That is convenient for tests and non-UI code, but it permits domain repair without plan repair.

Required change options:

Option A, preferred:

- Split APIs:
  - `retireNonNegotiable(id:referenceDate:)` for pure domain only, internal/test-only if possible.
  - `retireNonNegotiableWithPlanSync(id:referenceDate:planStore:)` for UI and app flows.
- Update all app call sites to use the sync variant.

Option B, smaller:

- Keep current API but add clear documentation and assertions/logging when a paused protocol is retired without `planStore`.
- Add the Step 3 repair pass so stale plan state converges on refresh.

Acceptance checks:

- Cockpit retirement of paused protocol immediately finalizes paused allocations.
- Any app UI retirement path passes `planStore`.
- A direct store retirement with `planStore: nil` is repaired by Plan refresh.

## Step 5 - Decide and implement suspended-at-expiry behavior

Priority: P0

Files:

- `LockedIn/Domain/Engines/CommitmentSystemEngine.swift`
- `LockedIn/Domain/Engines/NonNegotiableEngine.swift`
- `LockedIn/Application/CommitmentSystemStore.swift`

Problem:

`CommitmentSystemEngine.advanceWindows(currentDate:in:)` currently advances only active and recovery protocols. Suspended protocols are skipped. If a suspended protocol reaches lock end during recovery, it can remain suspended indefinitely unless another normalization path restores or terminalizes it.

Product decision needed:

Choose one rule:

Rule A, recommended:

- If suspended protocol reaches lock end, mark it `.completed`.
- Clear `recoveryPausedProtocolId` if it points to that protocol.
- Finalize its paused allocations as `.skippedDueToRecovery`.

Rule B:

- Keep suspended until recovery exits, then restore if capacity allows, then complete on the next window advance.
- This is more confusing because an expired protocol remains paused.

Recommended implementation:

- Update `advanceWindows(currentDate:in:)` to include `.suspended`.
- Let `NonNegotiableEngine.advanceWindowIfNeeded` mark it completed at lock end.
- After advancement, run `normalizeRecoveryDomain`.
- If a paused ID was cleared because the protocol became terminal, finalize plan allocations when planStore is available.

Acceptance checks:

- Suspended protocol whose lock ended yesterday becomes completed on daily tick.
- Its paused future allocations become skipped.
- It does not create new violations after lock end.
- Recovery pending state is cleared or recomputed if the paused protocol was the recovery pause target.

## Step 6 - Preserve historical recovery context in Logs

Priority: P1

Files:

- `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Optional model migration if adding persisted event metadata

Problem:

Logs mark entries as recovery-related using current owner state:

```swift
owner.state == .recovery || owner.state == .suspended
```

If a protocol was in recovery/suspended when the event happened but is later retired/completed/active, the historical entry can stop being recovery-related.

Implementation options:

Option A, no schema change:

- Treat violation entries that triggered recovery or happened while the protocol has a recovery marker as recovery-related.
- Use `recoveryRestoredAt`, violation type, and date ranges where possible.
- This is heuristic.

Option B, stronger:

- Add `wasRecoveryRelated: Bool` to `CompletionRecord` and/or `Violation`, default false.
- Set it when event is written while protocol is `.recovery` or `.suspended`, or when event causes recovery transition.
- Logs use the persisted flag instead of current state.

Recommended:

- Use Option B for correctness if model migration cost is acceptable.
- If not, implement Option A as an interim P1.

Acceptance checks:

- Violation logged during recovery still appears under recovery-related filter after protocol retires.
- Completion logged while protocol was in recovery still appears recovery-related after recovery exits.
- Normal completions before recovery do not appear recovery-related.

## Step 7 - Add focused lifecycle tests

Priority: P0

Files:

- `LockedInTests/LifecycleProtocolStateTests.swift` or extend `RecoveryModeTests.swift`
- Existing simulations may remain, but XCTest should cover core invariants.

Required tests:

1. Retired protocol is excluded from Plan queue and planning descriptors.
2. Completed protocol is excluded from Plan queue and planning descriptors.
3. Suspended protocol appears disabled in Plan queue.
4. Suspended selected protocol cannot place allocation through validation.
5. Paused allocation for retired protocol repairs to skipped on refresh.
6. Paused allocation for completed protocol repairs to skipped on refresh.
7. Past paused allocation repairs to skipped on refresh.
8. Suspended protocol at lock end completes or resolves according to Step 5 rule.
9. Daily expired protocol does not get violations after lock end.
10. Session protocol final partial week does not create misses after lock end.
11. Retiring paused protocol with plan sync finalizes paused allocations immediately.
12. Daily Check-In model excludes completed and retired protocols.
13. Cockpit active task model excludes completed and retired protocols.
14. Logs retain historical completed/violation records for terminal protocols.
15. Recovery-related log context is preserved after retirement/completion if Step 6 is implemented.

Manual QA checks:

- Create a protocol, plan it, retire it after lock end, confirm it disappears from queue and task surfaces.
- Enter recovery, pause a protocol, open Plan, confirm it is visibly paused and cannot be dragged or placed.
- Retire the paused protocol, reopen Plan, confirm paused allocations are skipped, not active or paused.
- Create a short protocol, skip past lock end, confirm no new misses appear after the end date.
- Open Logs after retirement/completion, confirm historical entries remain readable with correct protocol names.

## Recommended Execution Order

1. Step 1 - Gate Plan slot placement by validation.
2. Step 2 - Improve paused Plan copy and accessibility labels.
3. Step 3 - Add defensive PlanStore paused allocation repair.
4. Step 4 - Make retirement-with-plan-sync the safe app path.
5. Step 5 - Resolve suspended-at-expiry behavior.
6. Step 7 - Add tests for P0 lifecycle invariants.
7. Step 6 - Preserve historical recovery context in Logs.

Step 6 can be done after P0 if schema change is too large, but the current behavior should be explicitly deferred because it affects the "logs reflect lifecycle consistently" acceptance check.

## Definition of Done

This lifecycle step is complete when:

- No terminal protocol can be selected, dragged, planned, completed, or shown as current required work.
- Suspended protocols are visible only as disabled paused context with clear recovery copy.
- Plan slot affordances validate selected protocol state before showing as enabled.
- Paused allocations always converge to active or skipped based on protocol lifecycle state.
- Suspended protocols reaching lock end have a defined and tested behavior.
- Retired/completed protocols do not generate false misses.
- Plan, Logs, Cockpit/Home, and Daily Check-In reflect lifecycle states consistently.
- All P0 lifecycle tests pass.
