# ARCH-002 Ownership Rules and Responsibility Mapping Review

## Scope reviewed
- `/docs/refactor-ops/ownership-rules.md`
- `/docs/refactor-ops/responsibility-mapping.md`
- Consistency check against:
  - `/docs/refactor-ops/target-architecture.md`
  - `/docs/refactor-ops/decision-log.md`
  - audit anchors in `/docs/refactor-audit/` (`04`, `05`, `07`, `12`, `13`, `15`, `16`, `18`)

## Verdict
**Approved with recommendations**

These documents are strong enough to guide incremental ownership refactors and support QC judgment. The main remaining issues are precision and conflict-resolution clarity, not architecture direction.

## Review against requested focus

### 1) Clarity
**Strengths**
- `ownership-rules.md` is clearly structured by rule type (`OR-A*`, `OR-P*`, `OR-T*`) and ownership area.
- `responsibility-mapping.md` gives practical concern-to-owner mapping with current/target/transitional states.
- Both docs provide concrete anti-patterns and examples, which lowers interpretation drift.

**Clarity gaps**
- Some target-owner labels are still pattern-level rather than concrete implementation boundaries (for example “shared completion use-case/coordinator boundary”, “prompt-settings boundary”).
- Cross-document precedence is implicit. When a rule is strict but a decision is provisional (notably navigation semantics tied to `AD-006`), interpretation may vary.

### 2) Enforceability
**Strengths**
- Absolute rule IDs (`OR-A*`) are enforceable and tied to QC fail conditions.
- Transitional exception contract is explicit (ID, risk, removal trigger), which is operationally useful.
- QC checklist in Section 5 of responsibility mapping is practical and directly reviewable.

**Enforceability gaps**
- The docs do not define a formal conflict rule when `OR-A*` constraints intersect with provisional behavior uncertainties (`AD-006`, `AD-009`, `AD-014`).
- No normalized severity mapping from specific rule violations to verdict tier (Pass/Conditional Pass/Fail), beyond broad guidance.

### 3) Consistency with target architecture
**Consistent overall**
- Ownership rules align with target architecture constraints on boundary direction, single ownership, and no view-level persistence/orchestration.
- Responsibility mapping tracks target-architecture priorities (completion boundary, navigation intent lifecycle, persistence isolation, shared UI behavior extraction).

**Minor consistency risk**
- Target architecture distinguishes “immediately enforceable” vs aspirational per section, while ownership rules are presented as globally active for new/refactored slices. This is mostly compatible, but could be made explicit with a rule-level enforce-now/defer tag to avoid ambiguity.

### 4) Realism for incremental refactoring
**Strong realism**
- Transitional owners are explicitly allowed where legacy hotspots remain untouched.
- Stepwise extraction expectations are realistic for `PlanStore`/`CommitmentSystemStore` decomposition.
- The docs avoid big-bang assumptions and preserve behavior-first sequencing.

**Realism caution**
- `OR-A18` correctly requires behavior-lock strategy for high-risk moves, but practical ticket flow would benefit from an explicit “test bootstrap path” for early slices in the current near-zero-test baseline.

### 5) Developer boundary-decision usability
**Usable**
- Developer can make mostly correct boundary decisions using `OR-A*` + concern mapping table.
- “Must not own” column provides fast guardrails during implementation.

**Needs tighter guidance for edge cases**
- Add a short decision tree for common ambiguous cases (for example: “touching legacy code in scope-adjacent area”, “refactor requires temporary duplicated path”, “route-intent semantics uncertain”).

### 6) QC objectivity for ticket/implementation judgment
**Usable for objective review**
- Rule IDs and checklist items enable reproducible QC checks.
- Transitional exception requirements reduce subjective acceptance of legacy carryover.

**Objectivity improvements needed**
- Add explicit QC verdict rubric keyed to rule classes (for example: any undocumented `OR-T*` usage + `OR-A*` violation = Fail; `OR-P*` miss with documented follow-up = Conditional Pass).
- Add required evidence format per checklist item (files changed, rule IDs evaluated, tests present/absent with risk note) to standardize reviews across reviewers.

## Recommended revisions
1. Add a one-page precedence section: `Ticket scope > Provisional decision constraints > OR-A > OR-P > OR-T`, with examples.
2. Add enforceability tags per ownership rule (`Enforce now`, `Provisional`, `Deferred`) to mirror target-architecture semantics.
3. Add a QC rubric matrix mapping violation type (`OR-A`, undocumented `OR-T`, `OR-P`) to default verdict.
4. Add a compact developer decision tree for ambiguous migration cases.
5. Add a test-bootstrap note tied to `OR-A18` and `AD-012` to keep early incremental tickets actionable.

## Final judgment
The ownership framework is directionally strong, practical, and largely enforceable. With the rubric/precedence clarifications above, Developer decisions and QC verdicts will be more consistent and auditable across tickets.
