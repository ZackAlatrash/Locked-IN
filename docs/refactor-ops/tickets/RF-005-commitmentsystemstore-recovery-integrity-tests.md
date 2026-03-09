# RF-005 — CommitmentSystemStore Behavior-Lock Tests for Recovery and Daily Integrity Tick

## Why this ticket exists
`RF-004` locked the highest-value `PlanStore` behaviors. The next safety step is the matching coverage for `CommitmentSystemStore`, specifically the recovery transition and daily integrity behaviors that the audit identified as critical and regression-prone.

## Audit evidence
- `CommitmentSystemStore` is a critical god store with no automated protection:
  - `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-01`)
  - `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-003`)
- The priority map explicitly names recovery transitions and daily integrity tick as minimum safety work:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- Recovery flow is stateful and crosses feature boundaries:
  - `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`SF-02`)
  - `/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md`
- `CommitmentSystemStore` public behavior surface relevant to this ticket:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift`
  - symbols:
    - `runDailyIntegrityTick`
    - `recoveryEntryContext`
    - `pauseProtocolForRecovery`
    - `completeRecoveryEntryResolution`
    - `recordCompletionDetailed` only if needed for fixture evolution, not as primary scope

## Problem statement
`CommitmentSystemStore` currently has no behavior-lock coverage for the recovery and daily-integrity paths that later tickets will rely on. Without those tests, future recovery-flow, completion-orchestration, and persistence-boundary changes will carry high silent-regression risk.

## Goal
Add deterministic unit tests around the highest-value current `CommitmentSystemStore` behaviors:
- daily integrity tick behavior,
- recovery entry context behavior,
- pause-for-recovery behavior,
- recovery entry resolution behavior.

## In scope
- New tests under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/`
- New test support/test doubles required for `CommitmentSystemStore`:
  - in-memory `CommitmentSystemRepository` double
  - deterministic calendar/date helpers as needed
  - minimal `CommitmentSystem` / `NonNegotiable` fixture builders as needed
- Minimal production access changes only if required to make targeted observable behavior testable.

## Out of scope
- `PlanStore` tests.
- Cross-feature completion parity tests.
- `MainAppView` overlay or router tests.
- `CommitmentSystemStore` decomposition or production cleanup.
- Logging-policy cleanup, persistence-threading cleanup, or startup-reset policy changes.
- Any behavior change to current recovery or integrity semantics.

## Behavior constraints
- Tests must capture current observable behavior conservatively.
- Production runtime behavior must remain unchanged.
- If tests expose surprising current semantics, document them and lock them rather than “fixing” them in this ticket.

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
  - `/docs/refactor-ops/ownership-rules.md` `OR-A17` indirectly by protecting recovery/orchestration behavior before later ownership changes
- Transitional exceptions:
  - If minimal production visibility adjustments are needed for testability, they must be narrowly limited and documented.
- Ownership movement:
  - Current owner: untested `CommitmentSystemStore` recovery/integrity behavior
  - Target owner: same production owner, now protected by deterministic tests
- QC checks:
  - Ticket remains test-focused.
  - No hidden production refactor is bundled in.

## Required implementation changes
1. Add deterministic test doubles/support needed to construct and exercise `CommitmentSystemStore`.
2. Add focused tests covering, at minimum:
   - one daily-integrity tick path that changes observable store/system state,
   - one recovery-entry context path when recovery resolution is pending,
   - one pause-for-recovery path that updates paused protocol and recovery flags,
   - one completion of recovery-entry resolution path that clears pending-recovery state.
3. Keep fixtures minimal and local to the test target.
4. If minimal production-code visibility adjustments are necessary, keep them narrow and directly justified by testability.

## Required tests
Decision: **Tests required as part of this ticket.**

Required verification:
1. `LockedInTests` continues to pass with the new `CommitmentSystemStore` test file(s).
2. The new tests run deterministically with documented test doubles/helpers.
3. The tests exercise current `CommitmentSystemStore` behavior through public or minimally widened testable surfaces, not through UI or shell integration layers.

## Acceptance criteria
- `CommitmentSystemStore` has deterministic unit-test coverage for recovery/integrity behaviors in scope.
- Tests use test doubles/support rather than real persistence files.
- No production behavior changes are introduced.
- Any production-code visibility changes are minimal, documented, and strictly testability-driven.
- The new tests pass through a documented `xcodebuild test` command.

## Risks
- Recovery semantics may depend on fixture setup details; tests must avoid brittle overfitting.
- Production visibility changes could widen more surface area than necessary if not constrained.
- Fixture complexity may tempt scope creep into unrelated completion, logging, or UI behaviors.

## QC focus
- Confirm scope is limited to `CommitmentSystemStore` tests and necessary test support only.
- Confirm tests target observable current recovery/integrity behavior, not speculative future behavior.
- Confirm no production logic changes were introduced beyond narrowly justified testability adjustments.
- Confirm the added tests actually cover the intended high-risk behaviors named in the ticket.

## Completion notes required from Developer
Developer must provide:
- files changed
- list of added `CommitmentSystemStore` test cases and what each locks
- any production visibility/testability adjustments made
- exact `xcodebuild test` command used and result
- open ambiguities discovered in current recovery or daily-integrity behavior
