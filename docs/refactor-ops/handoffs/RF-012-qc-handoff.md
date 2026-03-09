# RF-012 — QC Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-012-plan-route-intent-lifecycle-semantics.md`

## Purpose
Review RF-012 for:
- explicit and conservative plan-intent lifecycle semantics,
- deterministic tests that protect the current router contract,
- strict containment of scope to plan route intent behavior.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-012-plan-route-intent-lifecycle-semantics.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-012-summary.md`

## Scope
- Validate the explicit lifecycle contract for plan focus/edit intents.
- Validate deterministic tests for that contract.
- Validate that scope stayed out of broader navigation/overlay/plan extraction work.

## Out of Scope
- Global overlay arbitration changes.
- Prompt-settings ownership changes.
- `PlanScreen` structural decomposition.
- Router redesign beyond the plan-intent contract surface.

## Priority Concerns
1. The ticket must clarify semantics, not redesign navigation.
2. Tests must lock the current contract, not a speculative future model.
3. Full-suite passing evidence is required.

## Required Output
- QC implementation review:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/reviews/RF-012-implementation-review.md`

Review verdict must include:
- `Pass`, `Conditional Pass`, or `Fail`
- what improved,
- whether the lifecycle contract is explicit and conservative,
- whether test evidence is sufficient,
- any scope creep findings,
- any required fixes.

## Pass criteria
- Plan focus/edit intent lifecycle semantics are explicit and test-backed.
- Focused tests pass.
- Full `LockedInTests` suite passes.
- No unrelated navigation or plan-screen refactor work was introduced.
