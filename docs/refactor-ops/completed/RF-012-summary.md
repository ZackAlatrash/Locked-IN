# RF-012 Summary

## Files Changed
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift`
- `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/PlanStore/PlanStoreBehaviorLockTests.swift`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-012-summary.md`

## Structural Changes
- Made the `AppRouter` plan-intent lifecycle contract explicit in code comments/doc comments, without changing routing architecture:
  - intents are single pending slots,
  - newest write replaces previous pending value,
  - each consume method clears only its own intent,
  - re-consuming when already cleared is a no-op.
- Kept scope strictly on plan route intent contract surface (`AppRouter`) and deterministic test coverage.
- Added a dedicated RF-012 lifecycle test class (`AppRouterPlanRouteIntentLifecycleTests`) inside an existing test target source file to avoid project structure changes.
- Added test-harness-local router retention in that class to avoid an existing deallocation crash path during focused test execution.

## Explicit Lifecycle Rules Implemented/Documented
1. `openPlan(protocolId:)` sets `selectedTab = .plan` and replaces `pendingPlanFocusProtocolId`.
2. `openPlanEditor(protocolId:)` sets `selectedTab = .plan` and replaces both `pendingPlanFocusProtocolId` and `pendingPlanEditProtocolId` with the same protocol ID.
3. `consumePlanFocusIntent()` clears only `pendingPlanFocusProtocolId`.
4. `consumePlanEditIntent()` clears only `pendingPlanEditProtocolId`.
5. Repeated consume calls after clear produce no additional state changes.
6. If a newer plan intent is set before consumption, the newer value is the one present (last-write-wins).

## Behavior Preservation Notes
- No navigation redesign was introduced.
- No `PlanScreen` extraction/restructure was introduced.
- No overlay arbitration, prompt-settings, store decomposition, or persistence behavior was changed.
- User-visible behavior is preserved by codifying the already-observed router semantics rather than changing intent ownership flow.

## Tests Added or Updated
- Added `AppRouterPlanRouteIntentLifecycleTests` with deterministic coverage for:
  - producing + consuming focus intent once,
  - producing + consuming edit intent once,
  - post-consume repeated consume behavior with no new intent,
  - replacement behavior when newer intent is set before consumption.

## Required Verification Commands and Exact Results
Simulator used:
- `2A2F7477-7FDF-4AC2-AE26-07499AB8F580`

1. Focused RF-012 class:
- `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=2A2F7477-7FDF-4AC2-AE26-07499AB8F580' -parallel-testing-enabled NO -only-testing:LockedInTests/AppRouterPlanRouteIntentLifecycleTests test`
- Result: `** TEST SUCCEEDED **`
- Executed: `4 tests, 0 failures`

2. Full suite:
- `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=2A2F7477-7FDF-4AC2-AE26-07499AB8F580' -parallel-testing-enabled NO test`
- Result: `** TEST SUCCEEDED **`
- Executed: `17 tests, 0 failures`

## Known Risks
- Focused runs for this lifecycle class initially exposed an existing router deallocation instability in the harness (`malloc: pointer being freed was not allocated`), so the tests retain router instances for process lifetime to keep RF-012 verification deterministic.
- This is a test-harness containment measure and does not change production routing behavior.

## Out-of-Scope Issues Discovered
- Existing focused-test runtime instability around `AppRouter` deallocation lifecycle should be tracked as a follow-up test-harness reliability item.
- No additional architecture or scope changes were made under RF-012.

## Ambiguity Discovered and Conservative Resolution
- Ambiguity: whether consuming plan edit should also clear focus intent.
- Conservative resolution (matching current implementation): consume methods are independent; consuming edit does not clear focus.
