# RF-008 — QC Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-008-remove-simulation-files-from-app-target-membership.md`

## Purpose
Review RF-008 for:
- correct removal of simulation files from the production app target,
- preservation of production behavior,
- strict limitation to project configuration cleanup.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-008-remove-simulation-files-from-app-target-membership.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/data/pbx_simulation_in_sources.txt`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-008-summary.md`

## Scope
- Validate simulation target-membership removal.
- Validate that the app target still builds.
- Validate that scope stayed inside project wiring.

## Out of Scope
- RF-007 stale-reference repair.
- Any runtime code review beyond checking for accidental scope creep.
- Build system redesign.

## Priority Concerns
1. The ticket must remove only the intended target-membership entries.
2. No unrelated pbx cleanup should be bundled in.
3. Build evidence must be explicit.

## Required Output
- QC implementation review:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-008-implementation-review.md`

Review verdict must include:
- `Pass`, `Conditional Pass`, or `Fail`
- what improved,
- any scope creep,
- whether the documented build evidence is sufficient,
- any required fixes.

## Pass criteria
- The audit-identified simulation files are no longer members of the `LockedIn` app target.
- The documented build command result is `BUILD SUCCEEDED`.
- No unrelated runtime or project cleanup was introduced.
