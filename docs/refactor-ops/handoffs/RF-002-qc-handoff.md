# RF-002 — QC Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-002-toolbar-actions-extraction-plan-logs.md`

## Purpose
Review RF-002 for:
- strict scope adherence,
- ownership-rule compliance for shared UI extraction,
- behavior preservation of toolbar actions.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-002-toolbar-actions-extraction-plan-logs.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md` (`OR-A15`, `OR-A16`, `OR-P05`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Section 8)
- Developer completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-002-summary.md`

## Scope
- Validate shared toolbar-actions extraction for Plan + Logs only.
- Validate behavior parity for logs/profile actions in those two screens.

## Out of Scope
- Expanding review scope into Cockpit main toolbar, routing contracts, or state/persistence layers.
- Requesting unrelated cleanup.

## Priority Concerns
1. Any hidden behavior change in logs/profile toolbar actions.
2. Shared component accidentally taking non-presentational responsibilities.
3. Scope creep in large surrounding files.

## Required Output
- QC implementation review:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-002-implementation-review.md`

Review verdict must include:
- Pass / Conditional Pass / Fail,
- improvements,
- defects/regressions,
- scope creep findings,
- required fixes.

## Notes
- Manual verification evidence is required for full approval.
- Missing manual-verification evidence should result in Conditional Pass or Fail depending on risk.
