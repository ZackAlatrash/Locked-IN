# RF-012 — Define and Test Plan Route Intent Lifecycle Semantics

## Why this ticket exists
The audit identified manual, timing-sensitive router intent consumption between `AppRouter` and `PlanScreen`. That creates dropped or duplicate deep-link risk, but this slice should stabilize semantics without broad navigation redesign.

This ticket is intentionally narrow: define the current lifecycle contract for plan focus/edit intents and protect it with deterministic tests.

## Audit evidence
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md`
  - `NV-02` manual router intent consumption is timing-sensitive
  - `NV-03` route control is scattered across non-navigation types
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
  - `PR-012` manual intent-consume navigation model
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
  - flow ownership stabilization must precede broader plan-flow extraction

## Problem statement
`AppRouter` produces plan focus/edit intents and `PlanScreen` consumes them manually. The current lifecycle semantics are implicit, message-like, and hard to reason about under repeated or fast route changes.

## Goal
Make plan route intent lifecycle semantics explicit and testable without redesigning the broader navigation architecture.

## In scope
- `AppRouter` plan focus/edit intent production and consume semantics.
- Deterministic tests for the chosen current-contract behavior.
- Minimal code changes needed to make the current lifecycle contract explicit in code and testable.
- Narrow documentation/comments in the touched routing code if needed to clarify semantics.

## Out of scope
- Replacing `AppRouter`.
- Broad `PlanScreen` navigation extraction.
- Global overlay arbitration changes (`RF-009` owns that work).
- Prompt-settings ownership changes (`RF-013` owns that work).
- Store decomposition, persistence work, or plan UI restructuring.

## Behavior constraints
- Preserve current user-visible navigation behavior.
- Choose the most conservative semantics that match current implementation rather than inventing a new routing model.
- If current behavior is ambiguous, document the chosen explicit contract and keep it as close as possible to current observable behavior.

## Architecture and ownership rules being enforced
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
  - Rule 1: preserve behavior
  - Rule 2: incremental refactoring
  - Rule 12: refactors must be reviewable
  - Rule 13: critical logic must be testable
  - Rule 14: tests protect behavior
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
  - `OR-A13`
  - `OR-A14`
  - `OR-A17`
  - `OR-T02`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md`
  - Section 11: cross-feature route requests use an explicit contract with lifecycle semantics
  - Section 14: migration should increase determinism and testability in small steps

## Ownership Rules
- Rules enforced now:
  - `OR-A13`
  - `OR-A14`
  - `OR-A17`
- Transitional exceptions:
  - `OR-T02`
    - Why needed: manual consume semantics remain in place during stabilization
    - Risk: lifecycle remains transitional until broader navigation cleanup
    - Removal trigger: a later explicit router/coordinator boundary ticket replaces manual consumption
- Ownership movement:
  - Current owner: implicit plan intent lifecycle spread across `AppRouter` and `PlanScreen`
  - Target owner: explicit, documented `AppRouter` plan intent contract protected by tests
- QC checks:
  - no broad navigation redesign,
  - tests cover intent production and consumption semantics,
  - touched code stays limited to the plan-intent contract surface.

## Required implementation changes
1. Define the current lifecycle contract for:
   - plan focus intent production,
   - plan edit intent production,
   - consumption behavior,
   - repeated consume behavior after the intent is cleared.
2. Add deterministic tests that lock this contract.
3. Make only the minimal routing-code changes required to expose clear semantics and testability.

## Required tests
Developer must add and run deterministic tests covering at minimum:
1. producing a plan focus intent and consuming it exactly once,
2. producing a plan edit intent and consuming it exactly once,
3. post-consume behavior when consume is called again without a new intent,
4. replacement behavior when a newer plan intent is set before consumption, if that is how current code behaves.

## Required verification
Developer must document:
1. Focused test command for the new plan-route-intent test class.
2. Full `LockedInTests` command.
3. Exact results for both commands.

Recommended command shape:
- `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO -only-testing:LockedInTests/<TEST_CLASS_NAME> test`
- `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -parallel-testing-enabled NO test`

## Acceptance criteria
- The plan route intent lifecycle is explicit enough to be read from code/tests without reconstructing `PlanScreen` timing behavior by hand.
- Deterministic tests cover the chosen intent lifecycle semantics.
- The focused test command passes.
- The full `LockedInTests` suite passes.
- Scope remains limited to plan route intent semantics and direct test support only.
- No broader navigation, overlay, or plan-screen restructure is introduced.

## Risks
- It is easy to drift into navigation redesign or `PlanScreen` extraction if scope is not enforced.
- The current behavior may contain ambiguity that needs to be documented, not “improved” silently.
- Testability changes can accidentally alter current intent replacement/clearing behavior if not kept narrow.

## QC focus
- Confirm the chosen lifecycle semantics are explicit and conservative.
- Confirm tests lock the current contract rather than a speculative future routing model.
- Confirm no adjacent navigation/overlay work was bundled in.
- Confirm full-suite test evidence is documented.

## Completion notes required from Developer
Developer must provide:
- files changed,
- explicit lifecycle rules implemented/documented,
- test cases added,
- exact focused and full-suite `xcodebuild test` commands,
- exact results,
- any ambiguity discovered in current behavior and how it was resolved conservatively.
