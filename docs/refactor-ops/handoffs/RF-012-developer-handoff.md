# RF-012 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-012-plan-route-intent-lifecycle-semantics.md`

## Purpose
Stabilize the `AppRouter` plan focus/edit intent lifecycle by making its current semantics explicit and covered by deterministic tests, without redesigning the broader navigation system.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-012-plan-route-intent-lifecycle-semantics.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift`
- `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`

## Scope
- Make plan focus/edit intent semantics explicit in the current router contract.
- Add deterministic tests that lock those semantics.
- Keep code changes narrow and local to the plan-intent lifecycle surface.

## Out of Scope
- `PlanScreen` extraction or plan UI cleanup.
- Overlay arbitration work (`RF-009`).
- Prompt-settings work (`RF-013`).
- Router replacement or broader navigation redesign.

## Priority Concerns
1. Preserve current user-visible behavior.
2. Choose the smallest explicit contract that matches current implementation.
3. Keep the work test-first and reviewable.

## Required Output
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-012-summary.md`

Summary must include:
- files changed,
- explicit lifecycle rules implemented/documented,
- tests added,
- exact focused test command,
- exact full-suite test command,
- exact results,
- any discovered ambiguity and the conservative resolution.

## Required verification
1. Focused test command for the new plan-route-intent lifecycle test class.
   - Required result: `TEST SUCCEEDED`
2. Full suite command:
   - `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO test`
   - Required result: `TEST SUCCEEDED`
