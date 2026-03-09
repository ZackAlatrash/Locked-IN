# RF-001 — Profile Sheet Container Extraction (Plan + Logs)

## Why this ticket exists
This is the first implementation slice to validate the refactor workflow with a low-blast structural change.  
Current code duplicates the same profile-sheet presentation wrapper in multiple screens. Extracting one shared wrapper improves structural consistency without changing behavior.

## Audit evidence
- UI duplication finding for repeated profile sheet presentation pattern:
  - `/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md` (UI-02)
  - Evidence paths in audit:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Structural risk context:
  - `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md` (large UI files increase drift risk)
- Workflow and sequencing fit:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md` (small safe slices; avoid giant rewrites)

## Problem statement
Identical profile-sheet container structure is repeated in multiple feature views. This increases drift risk for future modal policy changes and keeps shared UI behavior scattered.

## Goal
Extract one shared CoreUI profile-sheet container and adopt it in Plan and Logs profile sheet call sites, preserving all behavior.

## In scope
- Create one shared presentational component under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/CoreUI/Components/`
- Replace duplicated profile sheet container usage in:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Keep existing trigger state (`showProfile`) and sheet ownership in each screen.

## Out of scope
- Any navigation contract changes (`AppRouter`, intent consume behavior).
- Any store/state ownership changes (`PlanStore`, `CommitmentSystemStore`, ViewModels).
- Any persistence or `@AppStorage` changes.
- Any broader UI redesign or style changes.
- Cockpit route behavior outside this specific sheet extraction.

## Behavior constraints
- Opening/dismissing profile from Plan and Logs must behave exactly as today.
- No changes to tab flow, routing, or overlay precedence.
- No visual redesign; keep current presentation structure and content.

## Architecture rule being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 4: Views must be thin (reduce repeated container wiring).
  - Rule 12: Refactors must be reviewable.
- `/docs/refactor-ops/target-architecture.md`
  - Section 8: Shared UI/design system extraction via behavior-safe primitives.
- `/docs/refactor-ops/ownership-rules.md`
  - `OR-A15`: shared UI must stay presentational.
  - `OR-A16`: avoid new duplication in known shared clusters.

## Required implementation changes
1. Add a shared CoreUI component that wraps the profile screen container used by sheet presentations.
2. Use the new component in PlanScreen and CockpitLogsScreen profile sheet bodies.
3. Keep all existing call-site control flow and state ownership unchanged.
4. Do not move business logic into the shared component.

## Required tests
Decision: **No new automated tests required for this ticket**, with justification:
- This is a presentational wrapper extraction with no business logic changes.
- Repository currently lacks test harness coverage for this UI path; creating that harness is out of scope for this first workflow-validation slice.

Required manual verification:
1. Plan tab: open profile sheet, verify content loads, dismiss works.
2. Logs tab: open profile sheet, verify content loads, dismiss works.
3. Ensure no regressions in tab selection, overlays, or navigation interactions while profile sheet is shown/dismissed.

## Acceptance criteria
- One new shared CoreUI profile-sheet container exists and is used by Plan + Logs.
- Duplicated wrapper code for those two screens is removed.
- Behavior and presentation remain unchanged for profile sheet flow.
- No unrelated files or architectural concerns are modified.

## Risks
- UI consistency regression if container differences were unintentionally relied upon.
- Navigation regression if sheet container embedding changes route context.
- Test safety gap remains (manual-only verification for this slice).

## QC focus
- Confirm scope is limited to shared profile-sheet container extraction.
- Confirm no changes to routing semantics, store mutations, persistence, or prompt keys.
- Verify the two in-scope screens still present/dismiss profile identically.
- Flag any unrelated cleanup or expansion as scope creep.

## Completion notes required from Developer
Developer must provide:
- files changed
- summary of extraction and call-site replacements
- manual verification results for Plan + Logs profile sheet flow
- open concerns or deferred follow-ups (if any)
