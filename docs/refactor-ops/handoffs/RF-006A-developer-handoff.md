# RF-006A — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006A-parity-test-execution-repair.md`

## Upstream Context
- Original ticket:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`
- Failed QC review:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-006-implementation-review.md`
- Prior completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-006-summary.md`

## Purpose
Repair RF-006 so its parity coverage becomes executable and reviewable:
- fix the test-host abort affecting `CrossFeatureCompletionParityTests`,
- preserve RF-006's original parity-test intent,
- avoid reopening broader completion architecture work.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006A-parity-test-execution-repair.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-006-cross-feature-completion-parity-tests.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-006-implementation-review.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md`

## Scope
- Diagnose the parity test-host abort.
- Apply the smallest fix required to make:
  - `CrossFeatureCompletionParityTests`, and
  - the full `LockedInTests` suite
  execute successfully.
- Limit any production-code touch to the existing RF-006 Cockpit-local seam only if directly required by the crash root cause.

## Out of Scope
- Any new parity scenario beyond RF-006.
- Shared completion orchestrator extraction.
- Cockpit or DailyCheckIn architecture cleanup beyond crash repair.
- Store decomposition, navigation work, persistence hardening, or unrelated test cleanup.

## Priority Concerns
1. Root-cause the abort instead of papering over it.
2. Keep the fix smaller than the original RF-006 scope.
3. Do not broaden the Cockpit seam into a shared orchestration boundary.
4. Provide exact passing command evidence, not inferred success.

## Required Output
- In-scope repair changes only.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-006A-summary.md`

Summary must include:
- root cause of the abort,
- files changed,
- exact repair made,
- whether any parity assertions or fixture contracts changed,
- exact `xcodebuild test` commands used,
- exact results for parity-only and full-suite runs,
- any residual risk or bounded follow-up note.

## Required verification commands
1. `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO -only-testing:LockedInTests/CrossFeatureCompletionParityTests test`
   - Required result: `TEST SUCCEEDED`
2. `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO test`
   - Required result: `TEST SUCCEEDED`

## Notes
- If the root cause is test-harness lifecycle or teardown behavior, fix that directly.
- If a real parity mismatch is discovered while stabilizing execution, document it explicitly; do not silently change the assertions to hide it.
