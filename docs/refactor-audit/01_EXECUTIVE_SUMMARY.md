# 01 Executive Summary

## Purpose and scope
This document summarizes Pass B findings after cross-file tracing of runtime-critical flows in `/Users/zackalatrash/Desktop/Locked IN/LockedIn`.
Scope is architecture behavior as implemented today, not intended design.
No refactor or behavior changes were performed.

## Summary
Overall health is **Critical**. The codebase is not failing because of one bad file; it is failing because orchestration, state ownership, and persistence side effects are spread across Views, ViewModels, and Stores with no hard boundary enforcement.

- Severity: **Critical**
- Confidence: **High confidence**
- Primary root cause: **Responsibility collapse around global mutable stores (`CommitmentSystemStore`, `PlanStore`) plus UI-layer orchestration**.

## Root-cause diagnosis (not symptoms)
1. **Global mutable store coupling**
- Fact: `PlanStore` and `CommitmentSystemStore` are injected broadly across unrelated features (`Cockpit`, `Plan`, `DailyCheckIn`, `Recovery`, `DevOptions`, `AppShell`) and mutated from multiple locations.
- Evidence: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:13-17`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:14-17`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:15-17`.

2. **Flow ownership split across shell and feature screens**
- Fact: `MainAppView` owns overlay gating and prompt timing while feature screens also trigger routing intents.
- Evidence: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:73-180`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:174-191`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:390`.

3. **Rule logic duplicated in multiple feature layers**
- Fact: completion/reconciliation toast and scoring logic are reimplemented in multiple files.
- Evidence: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:353-376,486-494`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:196-219,434-456`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:162-189`.

## Interpretation
These are not isolated style issues. The architecture has drifted into shared mutable global state with duplicated feature-level orchestration and no consistent boundary contract.

## Future implication
Without staged stabilization, refactor work will carry high regression probability in navigation flow, persistence behavior, and cross-feature rule consistency.

## Top 10 architectural problems (actual)
| # | Problem | Severity | Confidence | Type | Evidence |
|---|---|---|---|---|---|
| 1 | `PlanScreen` is a god view (2396 LOC) with navigation, drag/drop, calendar auth, toasts, undo, modal orchestration | Critical | High confidence | Architecture risk / Maintainability risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:10-2396`; LOC evidence in `docs/refactor-audit/data/swift_loc_top_60.txt:1` |
| 2 | `PlanStore` is a god store: validation, queue building, week shaping, persistence writes, warning timers, reconciliation | Critical | High confidence | Architecture risk / Bug risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:51-1227` |
| 3 | `CommitmentSystemStore` mixes domain mutation, recovery transitions, log aggregation, persistence and UI-facing copies | Critical | High confidence | Architecture risk / Production risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:10-847` |
| 4 | UI layer performs business orchestration and multi-store mutation on action tap | High | High confidence | Wrong-layer logic / Bug risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:345-431` |
| 5 | Main shell runs policy/prompt orchestration with many reactive triggers; high re-entry surface | High | High confidence | Architecture risk / UX flow risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:142-180,255-330` |
| 6 | State duplication between `PlanStore` and `PlanViewModel` (same properties mirrored through Combine) | High | High confidence | Code smell / Architecture risk | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:79-115` vs `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:52-62` |
| 7 | Unstructured async timing in Views (`Task.sleep`, `DispatchQueue.main.asyncAfter`) drives UI state transitions | High | High confidence | Threading risk / UX fragility | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1415-1421,1516-1523,1537-1550`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:469-476`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift:87-93` |
| 8 | Production project includes simulation files in app Sources | Critical | High confidence | Production risk | `docs/refactor-audit/data/pbx_simulation_in_sources.txt:1-12` |
| 9 | Project metadata drift: missing file still referenced by pbxproj | High | High confidence | Production risk / Build fragility | `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt:1` |
| 10 | Safety net is effectively absent (no test target/files) | Critical | High confidence | Testing risk / Refactor risk | `docs/refactor-audit/data/project_target_inventory.txt:46-57`; `docs/refactor-audit/data/test_files_scan.txt` (empty) |

## Most dangerous production risks
- **Runtime flow deadlocks/UX conflicts** from overlay and modal ownership split (`MainAppView` + per-screen sheets).
- **Data integrity drift** from duplicated rule engines and repeated side-effect chains (`recordCompletionDetailed` + `reconcileAfterCompletion` + `runDailyIntegrityTick`) implemented in multiple features.
- **Release contamination risk** from simulation files in app target and active debug `print` statements in runtime stores.
- **High blast radius for any change** due to no meaningful automated tests.

## Rescue type required
This needs a **phased architectural rescue**, not file-by-file cleanup.

- Estimated refactor complexity: **High (multi-sprint, dependency-ordered)**
- Must avoid: giant-bang rewrite.
- Must start with: behavior locks/tests around store mutation and navigation flow ownership.

## Confidence after Pass B
- Overall confidence: **High confidence** on structural and risk findings.
- Medium-confidence area: dead-code certainty (still heuristic without full reference graph + runtime telemetry).

## Conclusion
The system is currently held together by shared mutable stores and view-level orchestration. That pattern is already causing architecture drift and creates unacceptable risk for any direct refactor without first establishing test coverage and ownership boundaries.
