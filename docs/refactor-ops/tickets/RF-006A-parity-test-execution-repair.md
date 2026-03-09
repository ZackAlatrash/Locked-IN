# RF-006A — RF-006 Parity Test Execution Repair

## Why this corrective ticket exists
RF-006 established the right parity-coverage direction, but QC failed the ticket because the required `xcodebuild test` execution evidence was not met. The parity-only command and the full `LockedInTests` command both aborted the test host before reliable approval evidence existed.

This corrective ticket preserves RF-006's original intent:
- keep the parity coverage approach,
- repair only the execution instability blocking approval,
- avoid reopening completion-boundary architecture work.

## Source references
- Original ticket:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`
- QC review:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-006-implementation-review.md`
- Developer completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-006-summary.md`
- Ledger status:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/refactor-ledger.md`

## Failure summary
QC recorded `Fail` for RF-006 because:
1. the documented parity-only `xcodebuild test` command failed,
2. the documented full-suite `xcodebuild test` command failed once `CrossFeatureCompletionParityTests` executed,
3. the failure mode was a test-host abort (`malloc: pointer being freed was not allocated`, `signal abrt`),
4. therefore RF-006 did not satisfy its required passing execution evidence.

## Goal
Make the existing RF-006 parity coverage execute successfully and reproducibly so QC can validate the original safety intent against passing test evidence.

## Exact repair scope
- Diagnose the specific cause of the `CrossFeatureCompletionParityTests` test-host abort.
- Apply the smallest repair needed to make the parity tests executable.
- If required, make narrowly scoped changes in:
  - parity test setup/teardown,
  - parity test fixtures/support,
  - test-target/test-host configuration,
  - the existing Cockpit-local testability seam only when directly necessary to eliminate the abort.
- Re-run and document passing commands for:
  - the parity test class only,
  - the full `LockedInTests` suite.

## In scope
- `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/Parity/CrossFeatureCompletionParityTests.swift`
- RF-006-specific test fixtures/support under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/`
- `LockedIn.xcodeproj/project.pbxproj` only if required for test-target execution repair.
- The existing Cockpit-local seam introduced by RF-006 only if directly required to prevent the abort.

## Out of scope
- New parity scenarios beyond RF-006's documented scope.
- Shared completion orchestrator extraction.
- Cockpit-to-DailyCheckIn completion consolidation.
- Broader Cockpit or DailyCheckIn architecture cleanup.
- `PlanStore` or `CommitmentSystemStore` decomposition.
- Navigation, overlay, router, persistence-policy, or release-target cleanup work.
- Any production behavior change unrelated to making the RF-006 tests execute reliably.

## Behavior constraints
- Preserve the original RF-006 parity intent and assertions unless a change is strictly required to eliminate invalid test-host lifecycle behavior.
- Do not normalize a real Cockpit-vs-DailyCheckIn behavioral mismatch just to get the tests green.
- Keep any production-code adjustment feature-local, narrow, and justified by the crash root cause.

## Architecture and ownership rules being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 13: Critical logic must be testable.
  - Rule 14: Tests protect behavior.
  - Rule 12: Refactors must be reviewable.
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
  - `OR-A17`
  - `OR-A18`
  - `OR-T01` only if a narrowly bounded RF-006 seam adjustment is required
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md`
  - Section 7: shared workflow convergence must stay explicit and staged
  - Section 13: cross-feature orchestration needs executable test protection before consolidation
  - Section 14: migration must preserve behavior and stay incremental

## Required implementation changes
1. Identify and fix the concrete cause of the RF-006 parity test-host abort.
2. Keep the repair bounded to parity test execution reliability.
3. Preserve RF-006's parity comparison scenarios unless the crash root cause requires a narrow harness-level adjustment.
4. Document the root cause and why the chosen fix is the smallest safe repair.

## Required verification commands and results to document
Developer must run and record:
1. Parity-only command:
   - `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO -only-testing:LockedInTests/CrossFeatureCompletionParityTests test`
   - Required result: `TEST SUCCEEDED`
2. Full test-suite command:
   - `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO test`
   - Required result: `TEST SUCCEEDED`

If a different deterministic simulator identifier is used, the summary must state the exact ID used.

## Acceptance criteria
- The RF-006 parity-only `xcodebuild test` command completes successfully without test-host abort.
- The full `LockedInTests` `xcodebuild test` command completes successfully without test-host abort when the suite reaches `CrossFeatureCompletionParityTests`.
- The repair remains tightly scoped to the QC fail reasons from RF-006.
- No broader completion-boundary extraction or hidden architecture work is introduced.
- The completion summary documents:
  - crash root cause,
  - exact files changed,
  - exact commands run,
  - exact results,
  - whether parity assertions remained unchanged or what minimal change was required.

## Risks
- The abort may be caused by fixture lifecycle issues rather than test assertions, so the repair must not drift into behavior redesign.
- `project.pbxproj` or test-host configuration changes can create avoidable scope creep if not strictly justified.
- A broad rewrite of the Cockpit seam would violate the corrective intent even if it makes the tests pass.

## QC focus
- Confirm the repair directly addresses the RF-006 fail reason instead of expanding the ticket.
- Confirm the parity-only and full-suite commands both pass and are documented exactly.
- Confirm any production-code changes are minimal, feature-local, and crash-driven.
- Confirm the parity coverage intent from RF-006 remains intact.

## Completion notes required from Developer
Developer must provide:
- root cause of the test-host abort,
- files changed,
- exact repair made,
- whether any parity assertion or fixture contract changed,
- exact `xcodebuild test` commands used,
- exact command results,
- any residual risk or follow-up note if the fix had to rely on a bounded exception.
