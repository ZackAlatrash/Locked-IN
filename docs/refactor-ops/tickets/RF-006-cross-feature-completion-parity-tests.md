# RF-006 — Cross-Feature Completion Parity Tests for Cockpit and DailyCheckIn

## Why this ticket exists
The next blocker before completion-boundary extraction is proving that the two current completion entry paths still produce equivalent core side effects. This ticket adds parity coverage first, so later consolidation work can proceed against a locked baseline instead of assumptions.

## Audit evidence
- Cross-feature completion chain is duplicated in two active paths:
  - `/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md` (`FD-02`)
  - `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-01`)
- Tests for that duplicated orchestration are explicitly missing:
  - `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-02`)
- Priority map requires parity testing before completion-boundary consolidation:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- Current duplicated code paths:
  - Cockpit:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift`
    - symbols:
      - `perform(.complete)`
      - `recordCompletionDetailed`
      - `reconcileAfterCompletion`
      - `runDailyIntegrityTick`
  - DailyCheckIn:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift`
    - symbols:
      - `markDone`
      - `recordCompletionDetailed`
      - `reconcileAfterCompletion`
      - `runDailyIntegrityTick`

## Problem statement
The same completion workflow is currently implemented in two different feature layers. Without parity tests, a later refactor could silently preserve one path while regressing the other, or consolidate around the wrong behavioral contract.

## Goal
Add integration-style tests that confirm the Cockpit completion path and DailyCheckIn completion path produce equivalent core store-side effects for the same deterministic scenario.

## In scope
- New tests under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/`
- New test support required to run both completion entry paths against shared deterministic fixtures.
- Minimal production testability seam only if required to exercise the Cockpit completion path without UI automation.

## Out of scope
- Introducing a shared completion orchestrator or completion-use-case boundary.
- Refactoring Cockpit or DailyCheckIn architecture beyond minimal testability seam.
- Router/overlay navigation tests beyond what is strictly needed to observe current completion-path side effects.
- `PlanStore` or `CommitmentSystemStore` decomposition.
- Any behavior change to current completion, reconciliation, or toast/warning semantics.

## Behavior constraints
- Tests must capture current parity, not impose a new completion design.
- Production runtime behavior must remain unchanged.
- If the two paths are already observably different, the ticket must document the difference and fail/flag rather than silently normalize behavior.

## Architecture rule being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 13: Critical logic must be testable.
  - Rule 14: Tests protect behavior.
  - Rule 12: Refactors must be reviewable.
- `/docs/refactor-ops/target-architecture.md`
  - Section 7: cross-feature behavior should move toward shared orchestration boundaries.
  - Section 13: integration-style tests for cross-store/cross-feature orchestration.
  - Section 14: protect behavior before consolidation.
- `/docs/refactor-ops/decision-log.md`
  - `AD-002`: safety-first sequencing.
  - `AD-007`: completion orchestration must converge to one shared boundary.
  - `AD-012`: testing is a gating architecture concern.

## Ownership Rules
- Rules enforced now:
  - `/docs/refactor-ops/ownership-rules.md` `OR-A17`
  - `/docs/refactor-ops/ownership-rules.md` `OR-A18`
- Transitional exceptions:
  - If the Cockpit path needs a minimal testability seam to be exercised without UI automation, that seam must stay feature-local and must not become the shared orchestration boundary.
- Ownership movement:
  - Current owner: duplicated, unprotected completion workflows in Cockpit and DailyCheckIn
  - Target owner: same duplicated production owners, now protected by parity tests prior to later consolidation
- QC checks:
  - Ticket remains test-first, not consolidation.
  - No hidden architecture rewrite is bundled in.

## Required implementation changes
1. Add deterministic parity tests that exercise both current completion entry paths against equivalent starting fixtures.
2. Assert parity for core side effects, at minimum:
   - counted/extra completion write outcome behavior,
   - `PlanStore` reconciliation side effects,
   - post-completion integrity-tick state changes,
   - compatible warning/toast outcome category for the tested scenario(s), where observable.
3. Add only the minimal test support needed to construct and compare both paths.
4. If a production testability seam is necessary for the Cockpit path, keep it feature-local, narrow, and explicitly documented.

## Required tests
Decision: **Tests required as part of this ticket.**

Required verification:
1. `LockedInTests` continues to pass with the new cross-feature parity test file(s).
2. The parity tests run deterministically with shared fixtures and documented support.
3. The tests exercise actual current feature-path behavior as closely as possible without broad UI automation or architectural extraction.

## Acceptance criteria
- There is deterministic parity coverage for Cockpit vs DailyCheckIn completion paths.
- The tests validate shared core side effects for equivalent scenarios.
- No production behavior changes are introduced.
- Any production testability seam is minimal, feature-local, documented, and not a premature shared orchestrator.
- The new tests pass through a documented `xcodebuild test` command.

## Risks
- The Cockpit completion path currently lives in a View action handler, which may require a narrow seam to make it testable.
- Tests may drift into partial completion-boundary extraction if scope is not enforced tightly.
- If the two paths already differ subtly, parity assertions may expose real product-contract ambiguity that needs explicit documentation.

## QC focus
- Confirm scope is limited to parity tests and necessary test support only.
- Confirm the tests compare the two real current paths rather than reimplementing a hypothetical shared helper.
- Confirm any production seam added for Cockpit is minimal and not a hidden consolidation step.
- Confirm parity assertions cover the intended shared side effects named in the ticket.

## Completion notes required from Developer
Developer must provide:
- files changed
- list of added parity test cases and what each compares
- any production testability seam introduced and why it was necessary
- exact `xcodebuild test` command used and result
- any discovered behavioral mismatch between Cockpit and DailyCheckIn paths
