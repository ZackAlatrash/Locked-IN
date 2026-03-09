# RF-001 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-001-profile-sheet-container-extraction.md`

## Purpose
Implement a low-risk structural extraction that validates refactor workflow mechanics:
- extract one shared profile-sheet container component,
- adopt it in Plan and Logs profile sheet call sites,
- preserve behavior.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-001-profile-sheet-container-extraction.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Section 8)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md` (`OR-A15`, `OR-A16`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md`

## Scope
- Add one shared presentational component in:
  - `LockedIn/CoreUI/Components/`
- Replace profile sheet container duplication in:
  - `LockedIn/Features/Plan/Views/PlanScreen.swift`
  - `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Keep trigger state and sheet presentation ownership in each feature unchanged.

## Out of Scope
- Router, intent, and tab-navigation behavior.
- Store/viewmodel/persistence modifications.
- Any behavior changes in profile flow.
- Any additional refactor not required for this extraction.

## Priority Concerns
1. Preserve behavior exactly for open/dismiss profile in Plan and Logs.
2. Keep shared component purely presentational.
3. Avoid scope creep into unrelated cleanup.

## Required Output
- Code changes for in-scope files only.
- Completion summary file:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-001-summary.md`

Summary must include:
- files changed,
- what was extracted,
- manual verification results (Plan + Logs profile sheet),
- open concerns.

## Notes
- Automated tests are not required for this slice per ticket decision.
- Manual verification is mandatory and must be documented.
