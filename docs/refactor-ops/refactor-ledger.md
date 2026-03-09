# LockedIn Refactor Ledger

## 2026-03-08

### RF-001 — Profile Sheet Container Extraction (Plan + Logs)
- Ticket: `/docs/refactor-ops/tickets/RF-001-profile-sheet-container-extraction.md`
- Review: `/docs/refactor-ops/reviews/RF-001-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-001-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Shared presentational wrapper extracted (`ProfileSheetContainer`).
- Plan and Logs migrated to shared profile-sheet container.
- Scope stayed bounded; no routing/store/persistence scope creep reported.

#### Closure note
- QC re-review recorded full approval with no required fixes.

### RF-002 — Toolbar Actions Extraction (Plan + Logs)
- Ticket: `/docs/refactor-ops/tickets/RF-002-toolbar-actions-extraction-plan-logs.md`
- Review: `/docs/refactor-ops/reviews/RF-002-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-002-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Shared presentational toolbar cluster extracted (`LogsProfileToolbarActions`).
- Plan and Logs migrated off duplicated logs/profile toolbar action wiring.
- Action ownership remained in feature call sites; no router/store/persistence scope creep reported.

#### Closure note
- QC review recorded full approval with no required fixes.

## 2026-03-09

### RF-006 — Cross-Feature Completion Parity Tests for Cockpit and DailyCheckIn
- Ticket: `/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`
- Review: `/docs/refactor-ops/reviews/RF-006-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-006-summary.md`
- Review verdict: **Fail**
- Status: **Corrective Step Required**

#### What improved
- Added a Cockpit-local completion seam (`CockpitCompletionExecutor`) instead of prematurely introducing a shared completion boundary.
- Added parity-oriented test coverage aimed at comparing current Cockpit and DailyCheckIn completion side effects under shared fixtures.
- Scope remained bounded to testability and parity coverage; QC did not identify blocking scope creep.

#### Blocking issue
- The documented parity-only `xcodebuild test` command failed with a test-host abort (`malloc: pointer being freed was not allocated`, `signal abrt`).
- The documented full-suite `xcodebuild test` command failed with the same abort once `CrossFeatureCompletionParityTests` executed.
- RF-006 acceptance criteria require passing, reproducible `xcodebuild test` evidence, so the ticket cannot be closed.

#### Corrective next step
- Keep the fix scoped to RF-006 and resolve the test-host abort affecting `CrossFeatureCompletionParityTests`.
- Re-run and document passing `xcodebuild test` commands for:
  - `CrossFeatureCompletionParityTests`
  - the full `LockedInTests` suite
- Avoid broadening the Cockpit-local seam into shared completion orchestration while repairing test execution.

### RF-003 — Add LockedIn Test Target and Baseline Test Support
- Ticket: `/docs/refactor-ops/tickets/RF-003-test-target-baseline-support.md`
- Review: `/docs/refactor-ops/reviews/RF-003-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-003-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Added a dedicated `LockedInTests` unit test target and baseline test folder structure.
- Established deterministic smoke-test support for future behavior-lock tests.
- Removed the test-infrastructure blocker identified in the audit and backlog.

#### Closure note
- QC review recorded full approval with no required fixes.

### RF-004 — PlanStore Behavior-Lock Tests for Placement and Reconciliation
- Ticket: `/docs/refactor-ops/tickets/RF-004-planstore-behavior-lock-tests.md`
- Review: `/docs/refactor-ops/reviews/RF-004-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-004-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Added deterministic `PlanStore` behavior-lock coverage for placement, move/remove, draft apply, and completion reconciliation.
- Established `PlanStore`-specific test fixtures and in-memory repository support for later plan-side test work.
- Reduced regression risk for future `PlanStore` and `PlanScreen` structural tickets.

#### Closure note
- QC review recorded full approval with no required fixes.

### RF-005 — CommitmentSystemStore Behavior-Lock Tests for Recovery and Daily Integrity Tick
- Ticket: `/docs/refactor-ops/tickets/RF-005-commitmentsystemstore-recovery-integrity-tests.md`
- Review: `/docs/refactor-ops/reviews/RF-005-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-005-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Added deterministic `CommitmentSystemStore` behavior-lock coverage for daily integrity tick and recovery-entry behaviors.
- Established `CommitmentSystemStore`-specific test fixtures and in-memory repository support for later recovery/completion test work.
- Reduced regression risk for future recovery-flow and completion-boundary tickets.

#### Closure note
- QC review recorded full approval with no required fixes.

### RF-006A — RF-006 Parity Test Execution Repair
- Ticket: `/docs/refactor-ops/tickets/RF-006A-parity-test-execution-repair.md`
- Review: `/docs/refactor-ops/reviews/RF-006A-implementation-review.md`
- Completion summary: `/docs/refactor-ops/completed/RF-006A-summary.md`
- Review verdict: **Pass**
- Status: **Completed**

#### What improved
- Resolved the RF-006 test-execution blocker by fixing the parity harness lifecycle issue in `CrossFeatureCompletionParityTests`.
- Documented passing `xcodebuild test` evidence for both the parity-only test class and the full `LockedInTests` suite.
- Kept the repair test-local and preserved RF-006's original parity assertions and bounded scope.

#### Closure note
- QC review recorded full approval with no required fixes.
- RF-006's previously recorded failure remains part of the trail; RF-006A is the corrective closure for the execution-evidence gap.
