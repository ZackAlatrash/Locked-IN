# 11_DEAD_CODE_UNUSED_CODE_AND_OBSOLETE_PATHS_AUDIT

## Purpose and Scope
Flag stale/unused/obsolete code signals with explicit confidence bands. This is a static pass, not a compiler-proof dead-code elimination report.

## Summary
- One **high-confidence stale project reference** is confirmed.
- Multiple **low/medium-confidence unused candidates** exist.
- Simulation harness files appear uninvoked and are still target-included.

## High-Confidence Findings
### Finding 1: Missing file still referenced by project metadata
- Type: Bug risk
- Severity: High
- Confidence: High confidence
- Evidence:
  - Missing referenced path: `LockedIn/Features/Onboarding/SubFeatures/IdentityWarning/ViewModels/IdentityWarningViewModel.swift`
  - Source: `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt`
- Why this is risky now:
  - Project tree lies about available source; can hide stale architecture assumptions.
- Pass B follow-up:
  - Remove/repair stale reference set and verify no additional missing paths.

## Medium-Confidence Findings
### Finding 2: Simulation files included in app build sources and appear detached from runtime paths
- Type: Production risk
- Severity: High
- Confidence: High confidence (for inclusion), Medium confidence (for runtime inactivity)
- Evidence:
  - Simulation files in Sources: `docs/refactor-audit/data/pbx_simulation_in_sources.txt`
  - Entry points found only at declaration sites in static scan: `docs/refactor-audit/data/deadcode_simulation_entrypoints_and_uses.txt`
- Why this is risky now:
  - Dead or dev-only code in shipping target increases risk surface and maintenance noise.
- Pass B follow-up:
  - Confirm whether these are intentionally callable under debug flags or truly obsolete.

### Finding 3: Root-level design artifacts may be stale relative to code source of truth
- Type: Code smell
- Severity: Low
- Confidence: Medium confidence
- Evidence:
  - Root includes multiple design export HTML/assets not in app source folders.
- Why this is risky now:
  - Repository signal-to-noise degradation.
- Pass B follow-up:
  - Verify retention policy and archival intent.

## Low-Confidence Heuristic Candidates
### Finding 4: Single-reference type candidates likely unused or preview-only
- Type: Code smell
- Severity: Medium
- Confidence: Low confidence
- Evidence:
  - `docs/refactor-audit/data/deadcode_single_reference_type_candidates.txt`
  - Includes `CockpitKpiCard`, `CockpitNonNegotiableCard`, `LiquidGlassNavDemosRootView`, `MockPlanCalendarProvider`, `PlaceholderAIService`, and many `*_Previews`.
- Why this is risky now:
  - Could indicate orphaned components or unfinished migrations.
- Pass B follow-up:
  - Use compiler/index-level reference analysis before deletion decisions.

## Commented-Out / Debug Code Signals
### Finding 5: Debug TODO/print usage appears in non-test app paths
- Type: Production risk
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - `//codex TODO move to viewModel` in `LockedIn/Features/Plan/Views/PlanScreen.swift:390`
  - `print(...)` in app stores/viewmodels and simulations (`docs/refactor-audit/data/pattern_logging_debug_locations.txt`)
- Why this is risky now:
  - Indicates incomplete cleanup and non-structured diagnostics in runtime code.
- Pass B follow-up:
  - Confirm production logging policy and target-specific debug fences.

## Caution Notes
- Single-reference and uninvoked-function heuristics can produce false positives.
- Some candidates may be consumed by SwiftUI previews, reflection, or indirect wiring.
- No dead-code deletion decisions should be made without Pass B cross-reference validation.

## Conclusion
Stale metadata is confirmed and must be treated as real drift. Additional unused-code signals are plausible but require stronger reference proof before action.
