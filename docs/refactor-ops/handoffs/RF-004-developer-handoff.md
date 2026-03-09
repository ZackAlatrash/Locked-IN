# RF-004 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-004-planstore-behavior-lock-tests.md`

## Purpose
Implement the first real behavior-lock coverage slice for `PlanStore`:
- add deterministic tests for placement, move/remove, draft apply, and completion reconciliation,
- keep scope inside the test target and minimal testability seams only.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-004-planstore-behavior-lock-tests.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Sections 13 and 14)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/decision-log.md` (`AD-002`, `AD-012`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift`

## Scope
- Add deterministic `PlanStore` tests under `LockedInTests/`.
- Add in-memory repository doubles / fixture builders / deterministic date helpers as needed.
- Make only minimal production access changes if strictly necessary for testability.

## Out of Scope
- `CommitmentSystemStore` tests.
- Cross-feature completion parity tests.
- `MainAppView` or routing tests.
- `PlanStore` decomposition or cleanup beyond narrow testability adjustments.
- Any production behavior change.

## Priority Concerns
1. Lock observable current behavior, not implementation details.
2. Keep production-code edits minimal and directly justified.
3. Prevent scope creep into broader plan feature behavior.

## Required Output
- In-scope test and test-support changes.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-004-summary.md`

Summary must include:
- files changed,
- new test cases added,
- any production testability adjustments,
- exact `xcodebuild test` command and result,
- open ambiguities in current behavior.

## Notes
- This ticket is a safety gate for later `PlanStore` and `PlanScreen` work.
- If a behavior is surprising, capture and test the current behavior unless the ticket explicitly authorizes a change.
