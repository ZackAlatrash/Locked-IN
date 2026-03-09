# RF-002 — Toolbar Actions Extraction (Plan + Logs)

## Why this ticket exists
After RF-001 validated the workflow with a safe shared-UI extraction, the next small structural slice is to remove another audited duplication hotspot: repeated top-bar logs/profile action wiring in Plan and Logs screens.

## Audit evidence
- Repeated top-bar action cluster identified:
  - `/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md` (UI-01)
  - Referenced call sites:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Large UI files increase drift probability:
  - `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`
- Scope/sequence safety constraints:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md` (small, reviewable slices; avoid multi-concern rewrites)

## Problem statement
Plan and Logs duplicate the same logs/profile toolbar control structure with local variations. This keeps shared UI behavior scattered and increases maintenance drift risk for navigation chrome.

## Goal
Extract one shared presentational toolbar-actions component for the logs/profile buttons and adopt it in Plan and Logs without changing behavior.

## In scope
- Add one shared presentational component in:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/CoreUI/Components/`
- Replace duplicated logs/profile toolbar action UI in:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- Keep existing local state ownership and action closures at call sites.

## Out of scope
- Any change to AppRouter or navigation intent semantics.
- Any change to store/viewmodel responsibilities.
- Any persistence, AppStorage, or startup lifecycle change.
- Cockpit main screen toolbar (`CockpitView`) and create-button behavior.
- Visual redesign, icon changes, animation changes, or accessibility text changes.

## Behavior constraints
- Plan screen logs button still routes to Logs tab exactly as before.
- Logs screen logs button behavior remains unchanged (even if currently a no-op).
- Profile button behavior and profile sheet presentation remain unchanged in both screens.
- Existing haptic behavior remains unchanged.

## Architecture rule being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 4: Views must be thin.
  - Rule 12: Refactors must be reviewable.
- `/docs/refactor-ops/target-architecture.md`
  - Section 8: Shared UI extraction by behavior-preserving primitives.
- `/docs/refactor-ops/ownership-rules.md`
  - `OR-A15`: shared UI components stay presentational.
  - `OR-A16`: avoid new duplication in known shared clusters.
  - `OR-P05`: prioritize shared behavioral UI primitives.

## Ownership Rules
- Rules enforced now:
  - `OR-A15`, `OR-A16`, `OR-P05`
- Transitional exceptions:
  - None expected.
- Ownership movement:
  - Toolbar logs/profile action UI container:
    - current owner: duplicated feature views (Plan + Logs)
    - target owner: shared CoreUI presentational component
  - Action behavior ownership remains in feature call sites (closures).
- QC checks:
  - Shared component has no business/persistence logic.
  - No expansion into router/store/persistence concerns.

## Required implementation changes
1. Create a reusable CoreUI component that renders:
   - logs bell action button (with indicator dot),
   - profile action button.
2. Component accepts styling and action closures as inputs; it must not own business logic.
3. Replace duplicated toolbar UI in PlanScreen and CockpitLogsScreen with the shared component.
4. Keep action semantics and accessibility labels unchanged.

## Required tests
Decision: **No new automated tests required**, with justification:
- Presentational component extraction only; no business logic or data flow change.
- Existing ticket pattern for UI-only extraction remains manual-verification based.

Required manual verification:
1. Plan tab:
   - tapping logs button navigates to Logs tab.
   - tapping profile button opens and dismisses profile sheet correctly.
2. Logs tab:
   - tapping profile button opens and dismisses profile sheet correctly.
   - tapping logs button behavior is unchanged.
3. Verify no regressions in toolbar appearance/accessibility labels for both screens.

## Acceptance criteria
- One new shared toolbar-actions CoreUI component exists and is used by Plan + Logs.
- Duplicated logs/profile toolbar container code is removed from those two screens.
- No behavior changes in logs/profile interactions.
- No unrelated architecture concerns are modified.

## Risks
- UI behavior regression if closure wiring changes action semantics.
- Subtle navigation regression if toolbar placement modifiers change.
- Manual-only verification risk if interaction checks are not executed/documented.

## QC focus
- Confirm strict scope (shared toolbar actions extraction only).
- Confirm shared component remains presentational.
- Confirm behavior parity for logs/profile actions in Plan and Logs.
- Confirm no scope creep into Cockpit main toolbar, router contracts, or persistence/state layers.

## Completion notes required from Developer
Developer must provide:
- files changed
- summary of extracted component and call-site replacements
- manual verification results for Plan and Logs toolbar action behavior
- open concerns and any deferred follow-up
