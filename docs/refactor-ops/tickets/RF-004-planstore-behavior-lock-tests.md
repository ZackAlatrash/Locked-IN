# RF-004 — PlanStore Behavior-Lock Tests for Placement and Reconciliation

## Why this ticket exists
With `RF-003` complete, the next safe step is not store decomposition. It is locking current `PlanStore` behavior behind deterministic tests so later structural work can proceed with regression protection.

## Audit evidence
- `PlanStore` is a critical god store with no automated protection:
  - `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-01`)
  - `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-002`)
- The priority map explicitly names `PlanStore` placement, draft apply, and reconcile-after-completion as minimum safety work:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- `PlanStore` mixes validation, persistence, and reconciliation in one owner:
  - `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-02`)
  - `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md`
- Relevant `PlanStore` public surface:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift`
  - symbols:
    - `validateProtocolPlacement`
    - `validateMove`
    - `moveAllocation`
    - `removeAllocation`
    - `validateDraft`
    - `applyDraft`
    - `reconcileAfterCompletion`

## Problem statement
`PlanStore` currently has no behavior-lock coverage for the mutation and validation paths that later tickets will depend on. That leaves every future `PlanScreen` / `PlanStore` change exposed to silent regressions in placement rules, mutation results, and completion reconciliation.

## Goal
Add deterministic unit tests around the highest-value current `PlanStore` behaviors:
- placement validation,
- move/remove mutation behavior,
- draft apply behavior,
- reconcile-after-completion behavior.

## In scope
- New tests under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/`
- New test support/test doubles required for `PlanStore`:
  - in-memory `PlanAllocationRepository` double
  - deterministic calendar/date helpers as needed
  - fixture builders for minimal `CommitmentSystem` / protocol descriptors if needed
- Minimal production access changes only if required to make the targeted public behavior testable.

## Out of scope
- `CommitmentSystemStore` tests.
- Cross-feature completion parity tests.
- `MainAppView` or router/navigation tests.
- `PlanStore` decomposition or production logic cleanup.
- Any behavioral change to current placement or reconciliation semantics.
- New use-case boundaries, repository redesign, or persistence-threading changes.

## Behavior constraints
- Tests must lock current observable behavior, not redefine it.
- Production runtime behavior must remain unchanged.
- If a test reveals unclear current behavior, capture the current behavior conservatively and document uncertainty rather than “fixing” it in this ticket.

## Architecture rule being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 13: Critical logic must be testable.
  - Rule 14: Tests protect behavior.
  - Rule 12: Refactors must be reviewable.
- `/docs/refactor-ops/target-architecture.md`
  - Section 13: Application orchestration/store logic needs behavior-lock tests.
  - Section 14: Protect behavior first before decomposition.
- `/docs/refactor-ops/decision-log.md`
  - `AD-002`: safety-first sequencing.
  - `AD-012`: testing is a gating architecture concern.

## Ownership Rules
- Rules enforced now:
  - `/docs/refactor-ops/ownership-rules.md` `OR-A18`
  - `/docs/refactor-ops/ownership-rules.md` `OR-A04` indirectly by protecting current state-owner behavior before later ownership changes
- Transitional exceptions:
  - If minimal production visibility adjustments are needed for testability, they must be narrowly limited and documented.
- Ownership movement:
  - Current owner: untested `PlanStore` behavior
  - Target owner: same production owner, now protected by deterministic tests
- QC checks:
  - Ticket remains test-focused.
  - No hidden production refactor is bundled in.

## Required implementation changes
1. Add deterministic test doubles/support needed to construct and exercise `PlanStore`.
2. Add focused tests covering, at minimum:
   - one successful placement/validation path,
   - one blocked placement or blocked move path,
   - move/remove mutation behavior,
   - draft apply success or failure semantics,
   - reconcile-after-completion releasing the expected future allocation behavior.
3. Keep test fixtures minimal and local to the test target.
4. If minimal production-code visibility adjustments are necessary, keep them narrow and directly justified by testability.

## Required tests
Decision: **Tests required as part of this ticket.**

Required verification:
1. `LockedInTests` continues to pass with the new `PlanStore` test file(s).
2. The new tests run deterministically with documented test doubles/helpers.
3. The tests exercise current `PlanStore` behavior through public or minimally widened testable surfaces, not through unrelated UI layers.

## Acceptance criteria
- `PlanStore` has deterministic unit-test coverage for placement/move/remove/draft/reconciliation behaviors in scope.
- Tests use test doubles/support rather than real persistence files.
- No production behavior changes are introduced.
- Any production-code visibility changes are minimal, documented, and strictly testability-driven.
- The new tests pass through a documented `xcodebuild test` command.

## Risks
- Tests may overfit to implementation details instead of observable behavior.
- Production visibility changes could widen more surface area than necessary if not constrained.
- `PlanStore` fixture setup may tempt broader test scope creep into unrelated plan features.

## QC focus
- Confirm scope is limited to `PlanStore` tests and necessary test support only.
- Confirm tests target observable current behavior, not speculative new behavior.
- Confirm no production logic changes were introduced beyond narrowly justified testability adjustments.
- Confirm the added tests actually cover the intended high-risk paths named in the ticket.

## Completion notes required from Developer
Developer must provide:
- files changed
- list of added `PlanStore` test cases and what each locks
- any production visibility/testability adjustments made
- exact `xcodebuild test` command used and result
- open ambiguities discovered in current `PlanStore` behavior
