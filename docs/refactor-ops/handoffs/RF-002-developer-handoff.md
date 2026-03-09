# RF-002 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-002-toolbar-actions-extraction-plan-logs.md`

## Purpose
Implement the next bounded shared-UI extraction:
- create one shared logs/profile toolbar-actions component,
- migrate Plan + Logs call sites,
- preserve behavior exactly.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-002-toolbar-actions-extraction-plan-logs.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md` (`OR-A15`, `OR-A16`, `OR-P05`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Section 8)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md`

## Scope
- Add one new shared CoreUI presentational component in:
  - `LockedIn/CoreUI/Components/`
- Replace duplicated logs/profile toolbar action UI in:
  - `LockedIn/Features/Plan/Views/PlanScreen.swift`
  - `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Keep existing behavior and action ownership at call sites.

## Out of Scope
- Cockpit main toolbar and create-button wiring.
- AppRouter contract or intent lifecycle changes.
- Store/viewmodel/persistence/AppStorage changes.
- Visual redesign or accessibility label changes.

## Priority Concerns
1. Preserve behavior parity for all logs/profile toolbar actions.
2. Keep shared component purely presentational.
3. Avoid unrelated edits in large feature files.

## Required Output
- In-scope code changes only.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-002-summary.md`

Summary must include:
- files changed,
- extraction details,
- manual verification results for Plan + Logs toolbar interactions,
- open concerns (if any).

## Notes
- No new automated tests are required for this ticket.
- Manual verification is required and must be documented concretely.
