# 02_PROJECT_STRUCTURE_AUDIT

## Purpose and Scope
Document current project/folder structure and identify structural drift using only evidence from repository layout and project metadata.

## Summary
Structure style is **mixed**:
- Feature-first under `LockedIn/Features/*`
- Layer-first under `LockedIn/App`, `Application`, `Core`, `CoreUI`, `Domain`

This mixed style is not inherently wrong, but current implementation shows drift and unclear boundaries.

## Folder Structure Overview
### Source root (`LockedIn/`)
- `App`
- `Application`
- `Core`
- `CoreUI`
- `Domain`
- `Features`
- `Resources`

Evidence: `docs/refactor-audit/data/lockedin_tree_maxdepth8.txt`

### Swift distribution by top-level layer
| Layer | Swift files |
|---|---:|
| Features | 50 |
| Domain | 27 |
| CoreUI | 9 |
| Application | 8 |
| Core | 7 |
| App | 1 |

Evidence: `docs/refactor-audit/data/swift_layer_counts.txt`

### Feature distribution
| Feature | Swift files |
|---|---:|
| Onboarding | 17 |
| Cockpit | 14 |
| DailyCheckIn | 7 |
| Recovery | 4 |
| Plan | 3 |
| DevOptions | 3 |
| AppShell | 2 |

Evidence: `docs/refactor-audit/data/swift_feature_counts.txt`

## Findings
### Finding 1: Structure is mixed without strong enforcement boundaries
- Type: Architecture risk
- Severity: High
- Confidence: High confidence
- Evidence:
  - Coexistence of global layer folders (`Application`, `Domain`) and feature folders (`Features/*`) in same target.
  - `Features` contains only 50/102 Swift files; substantial behavior still lives outside feature capsules (`docs/refactor-audit/data/swift_layer_counts.txt`).
- Why this is risky now:
  - Makes dependency direction and ownership ambiguous during change.
- Pass B follow-up:
  - Build dependency graph to identify actual direction violations.

### Finding 2: Onboarding subtree contains empty ViewModel folders (structural drift)
- Type: Code smell
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - `LockedIn/Features/Onboarding/SubFeatures/FailureLoop/ViewModels` has `0` files.
  - `LockedIn/Features/Onboarding/SubFeatures/IdentityWarning/ViewModels` has `0` files.
- Why this is risky now:
  - Signals abandoned or partial architecture migration; increases false assumptions about ownership.
- Pass B follow-up:
  - Verify intended ownership for these subfeatures and whether ViewModels were removed or never implemented.

### Finding 3: pbx references include missing path in source tree
- Type: Bug risk
- Severity: High
- Confidence: High confidence
- Evidence:
  - Missing referenced path: `LockedIn/Features/Onboarding/SubFeatures/IdentityWarning/ViewModels/IdentityWarningViewModel.swift`
  - Source: `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt`
- Why this is risky now:
  - Build/project config drift; increases risk of broken references and misleading project navigation.
- Pass B follow-up:
  - Resolve stale reference set and verify no hidden target/file mismatch remains.

### Finding 4: Non-app artifacts live at repo root and are not clearly segregated
- Type: Code smell
- Severity: Low
- Confidence: High confidence
- Evidence:
  - Root contains design exports and HTML artifacts: `Core_Differentiation_Screen.html`, `stitch_design.html`, `uidesign.html`, `stitch_exports/*`.
- Why this is risky now:
  - Noise increases audit and maintenance cost; easy to confuse source of truth.
- Pass B follow-up:
  - Confirm artifact retention policy and ownership.

## Structural Inconsistencies and Suspicious Groupings
- `Plan` feature has 3 files (`Models/ViewModels/Views`) but pushes heavy behavior into `Application/PlanStore.swift`.
- `AppShell` owns global flow (`MainAppView`, `AppRouter`) while domain-critical flow toggles are driven by environment objects and app storage keys across screens.
- UI utility and style layers (`CoreUI`) coexist with extensive hard-coded styling in feature views.

## Conclusion
Current structure is neither cleanly feature-contained nor strictly layered. Most risk comes from ownership ambiguity and stale structural artifacts, not from directory naming alone.
