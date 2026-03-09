# ARCH-001 Target Architecture and Decision Log Review

## Scope reviewed
- `/docs/refactor-ops/target-architecture.md`
- `/docs/refactor-ops/decision-log.md`
- Cross-check against audit evidence in `/docs/refactor-audit/` (especially `01`, `04`, `07`, `12`, `13`, `14`, `15`, `16`, `18`).

## Verdict
**Approved with recommendations**

The architecture direction is materially aligned with the audit and is suitable as a refactor baseline. It is mostly incremental, safety-oriented, and implementable by Developer. The remaining issues are clarity and enforcement precision, not fundamental direction.

## Assessment by requested focus

### 1) Clarity
**What is clear**
- Clear separation between transitional target and aspirational end-state.
- Good use of explicit constraints (behavior preservation, one objective per ticket, no mega-ticket decomposition).
- Decision log entries are consistently formatted (ID/date/status/rationale/consequences).

**Clarity gaps**
- `target-architecture.md` says “selected rules only (marked below)” are immediately enforceable, but enforce-now markers are uneven across sections. Some sections read as mandatory without explicit enforceability labeling.
- The relationship between architecture rules and unresolved product uncertainties (`UQ-*`) is not explicit at section level; this may cause overconfident interpretation of still-provisional areas.

### 2) Realism
**Strong realism signals**
- Explicit rejection of big-bang rewrites and mass folder moves is realistic given current coupling and blast radius.
- Transitional “legacy stores while decomposing” model matches current state rather than assuming greenfield replacement.
- Adapter-first migration and one-caller-at-a-time guidance is realistic for this codebase.

**Realism risk**
- Testing expectations are correct but aggressive relative to current zero-test baseline (`TS-01..TS-04`). The docs should call out an explicit bootstrap expectation for test infrastructure so tickets do not stall on implied prerequisites.

### 3) Consistency with audit findings
**Consistent overall**
- Direction maps well to confirmed findings: responsibility collapse (`RB-*`), state duplication (`ST-*`), navigation fragility (`NV-*`), persistence risks (`DP-*`), concurrency fragility (`CC-*`), and test vacuum (`TS-*`).
- Sequencing in decisions (`AD-002`, `AD-013`) matches the priority map in `16_REFACTOR_PRIORITY_MAP.md`.

**Coverage gap**
- Audit-critical release-integrity issues (simulation files in app Sources, project metadata drift) are present in audit outputs and priority map but are not represented as a dedicated architecture decision in `decision-log.md`. This can underweight a critical risk stream.

### 4) Suitability for incremental refactoring
**Suitable**
- Strong incremental controls: vertical slices, behavior locks first, explicit defer/enforce classification per ticket, no concurrent decomposition of `PlanScreen` + `PlanStore` + `CommitmentSystemStore`.
- “No hidden refactors” and traceability requirements are compatible with QC reviewability.

**Improvement needed**
- Add a compact “minimum enforce-now checklist” for ticket authors (cross-cutting non-negotiables), so incremental enforcement does not vary by author interpretation.

### 5) Developer implementability
**Mostly implementable**
- Developer can implement against this with high reliability for most ticket types.
- Dependency direction and boundary ownership are concrete enough for day-to-day decisions.

**Potential implementation ambiguity**
- Navigation policy is marked provisional in `AD-006`, but target-architecture navigation section reads more definitive. This should be reconciled by explicitly tagging provisional semantics in the architecture doc where applicable.

### 6) Broad / vague / idealized risk
**Not too broad overall**
- The document explicitly frames end-state as aspirational and transitional constraints as immediate.

**Where it trends idealized**
- End-state module taxonomy (e.g., full Domain Ports/UseCases + DesignSystem destination) is acceptable as long as it remains non-binding for near-term tickets. A brief “do not require structural conformance to end-state in current tickets” reminder would reduce misuse.

## Recommended revisions
1. Add explicit enforceability tags (`Enforce now` vs `Aspirational/Deferred`) to every major section, not only selected sections.
2. In navigation and persistence sections, annotate rules affected by open questions (`UQ-01`, `UQ-03`, `UQ-06`, etc.) as provisional constraints.
3. Add one decision-log entry for release-integrity risk handling (simulation-source inclusion and project metadata drift), grounded in audit and priority map evidence.
4. Add a short testing bootstrap note (how early tickets should establish baseline test infrastructure before broader behavior-lock expectations are applied).

## Final judgment
Architecture direction is sound, audit-grounded, and incrementally usable. With the clarifications above, it will be significantly more reliable as an execution contract for Developer and a stricter baseline for QC enforcement.
