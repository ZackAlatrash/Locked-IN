# RF-005 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-005-commitmentsystemstore-recovery-integrity-tests.md`

## Purpose
Implement the next behavior-lock coverage slice for `CommitmentSystemStore`:
- add deterministic tests for daily integrity tick and recovery-state transitions,
- keep scope inside the test target and minimal testability seams only.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-005-commitmentsystemstore-recovery-integrity-tests.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Sections 13 and 14)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/decision-log.md` (`AD-002`, `AD-012`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift`

## Scope
- Add deterministic `CommitmentSystemStore` tests under `LockedInTests/`.
- Add in-memory repository doubles / fixture builders / deterministic date helpers as needed.
- Make only minimal production access changes if strictly necessary for testability.

## Out of Scope
- `PlanStore` tests.
- Cross-feature completion parity tests.
- `MainAppView` / overlay / router tests.
- `CommitmentSystemStore` decomposition or cleanup beyond narrow testability adjustments.
- Any production behavior change.

## Priority Concerns
1. Lock observable current recovery/integrity behavior, not implementation details.
2. Keep production-code edits minimal and directly justified.
3. Prevent scope creep into broader completion, logging, or UI behavior.

## Required Output
- In-scope test and test-support changes.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-005-summary.md`

Summary must include:
- files changed,
- new test cases added,
- any production testability adjustments,
- exact `xcodebuild test` command and result,
- open ambiguities in current behavior.

## Notes
- This ticket is a safety gate for later recovery-flow and completion-boundary work.
- If current recovery behavior is surprising, capture and test it unless the ticket explicitly authorizes a change.
