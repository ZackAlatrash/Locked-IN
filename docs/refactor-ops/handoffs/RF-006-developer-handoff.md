# RF-006 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`

## Purpose
Implement the cross-feature completion parity safety slice:
- add deterministic parity tests for Cockpit and DailyCheckIn completion flows,
- keep scope inside tests and minimal feature-local testability seams only,
- do not consolidate the workflows yet.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Sections 7, 13, 14)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/decision-log.md` (`AD-002`, `AD-007`, `AD-012`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift`

## Scope
- Add deterministic parity tests under `LockedInTests/`.
- Add shared test support required to run equivalent completion scenarios.
- Add only the narrowest feature-local seam needed to exercise the Cockpit completion path if direct testing is otherwise impractical.

## Out of Scope
- Shared completion orchestrator extraction.
- DailyCheckIn or Cockpit architectural cleanup unrelated to testability.
- Router/overlay behavior tests beyond what is strictly required to compare completion-path outcomes.
- `PlanStore` / `CommitmentSystemStore` decomposition.
- Any production behavior change.

## Priority Concerns
1. Compare the two real current paths, not a hypothetical refactor target.
2. Keep any Cockpit testability seam minimal and feature-local.
3. Prevent accidental completion-boundary consolidation in this ticket.

## Required Output
- In-scope parity tests and test-support changes.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-006-summary.md`

Summary must include:
- files changed,
- new parity test cases added,
- any production testability seam introduced,
- exact `xcodebuild test` command and result,
- any discovered path mismatch.

## Notes
- This ticket is the final safety gate before completion-boundary consolidation work.
- If the two paths are not actually equivalent, document the mismatch explicitly instead of normalizing it silently.
