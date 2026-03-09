# 03_FILE_SIZE_AND_COMPLEXITY_AUDIT

## Purpose and Scope
Measure file-size concentration and complexity proxies (large types, long functions) to identify likely god files and responsibility overload.

## Summary
Complexity concentration is severe and localized.

- `102` Swift files, `22,025` LOC total
- `43` files >150 LOC
- `20` files >300 LOC
- `8` files >500 LOC
- `4` files >1000 LOC

Evidence: `docs/refactor-audit/data/metrics_summary.txt`

## Largest Files by LOC
| Rank | File | LOC |
|---:|---|---:|
| 1 | `LockedIn/Features/Plan/Views/PlanScreen.swift` | 2396 |
| 2 | `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift` | 1366 |
| 3 | `LockedIn/Application/PlanStore.swift` | 1227 |
| 4 | `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift` | 1013 |
| 5 | `LockedIn/Application/CommitmentSystemStore.swift` | 847 |
| 6 | `LockedIn/Features/Cockpit/Views/CockpitView.swift` | 766 |
| 7 | `LockedIn/Features/Cockpit/Views/CockpitModernView.swift` | 672 |
| 8 | `LockedIn/Features/Plan/ViewModels/PlanViewModel.swift` | 604 |

Evidence: `docs/refactor-audit/data/swift_loc_top_60.txt`

## Large Types (Heuristic)
Top type-size detections:
- `final class CommitmentSystemStore: ObservableObject` (~838 lines)
- `final class PlanStore: ObservableObject` (~513 lines)
- `final class DailyCheckInViewModel: ObservableObject` (~395 lines)
- `final class PlanViewModel: ObservableObject` (~387 lines)
- `final class CommitmentSystemEngine` (~375 lines)
- `struct PlanScreen: View` (~224 lines for top struct only; file much larger)

Evidence: `docs/refactor-audit/data/large_type_heuristics.txt`

## Long Functions (Heuristic)
Notable long-function hotspots:
- `PlanRegulatorEngine.regulate` ~161 lines (`LockedIn/Domain/Engines/PlanRegulatorEngine.swift:10`)
- `CockpitViewModel.todayTasks` ~144 lines (`LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:218`)
- `DailyCheckInViewModel.refresh` ~139 lines (`LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:47`)
- `PlanViewModel.runRegulator` ~69 lines (`LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:214`)
- `PlanScreen.queueCard` ~97 lines (`LockedIn/Features/Plan/Views/PlanScreen.swift:458`)

Evidence: `docs/refactor-audit/data/long_function_heuristics.txt`

## Findings
### Finding 1: `PlanScreen` is a god view with broad behavioral surface
- Type: Architecture risk
- Severity: Critical
- Confidence: High confidence
- Evidence:
  - File size: `2396` LOC.
  - Contains navigation, modal control, drag/drop board interaction, calendar access triggers, and state orchestration.
  - Multiple sheets and router consumption (`LockedIn/Features/Plan/Views/PlanScreen.swift:103-168`, `:174-182`, `:1482`, `:1491`).
- Why this is risky now:
  - Any change in plan flow has high regression blast radius.
- Pass B follow-up:
  - Behavioral slicing map by sub-flow before any extraction.

### Finding 2: `PlanStore` and `CommitmentSystemStore` are overloaded cross-domain state engines
- Type: Architecture risk
- Severity: High
- Confidence: High confidence
- Evidence:
  - `PlanStore.swift` 1227 LOC with validation, persistence, planning, warnings, and reconciliation paths.
  - `CommitmentSystemStore.swift` 847 LOC with policy mediation, mutation, persistence, recovery transition management.
  - Declaration-density proxy places these files at top (`docs/refactor-audit/data/declaration_density_proxy_sorted.txt`).
- Why this is risky now:
  - High coupling; behavior is difficult to isolate for tests/refactors.
- Pass B follow-up:
  - Identify separable responsibilities and mutation boundaries.

### Finding 3: Massive secondary UI files increase duplication and drift probability
- Type: Code smell
- Severity: High
- Confidence: High confidence
- Evidence:
  - `CreateNonNegotiableView.swift` 1366 LOC
  - `CockpitLogsScreen.swift` 1013 LOC
  - `CockpitView.swift` 766 LOC
  - `CockpitModernView.swift` 672 LOC
- Why this is risky now:
  - Visual/behavioral inconsistency risk increases when related UI is distributed across very large files.
- Pass B follow-up:
  - Map repeated sections/components and reusable primitives.

### Finding 4: Simulation/test harness functions are among the longest functions
- Type: Production risk
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - Top two longest functions are simulation runners (`NonNegotiableEngineSimulation`, `CommitmentSystemSimulation`).
  - See `docs/refactor-audit/data/long_function_heuristics.txt`.
- Why this is risky now:
  - Large non-production logic co-located in app target adds noise and potential leakage risk.
- Pass B follow-up:
  - Validate target membership and isolation strategy.

## Likely Split Candidates (for later, no refactor in Pass A)
- `PlanScreen.swift`
- `PlanStore.swift`
- `CreateNonNegotiableView.swift`
- `CockpitLogsScreen.swift`
- `CommitmentSystemStore.swift`
- `PlanViewModel.swift`

## Conclusion
Complexity is not evenly distributed; it is concentrated in a few files that currently act as behavior hubs. These hubs are the primary maintainability and refactor-risk drivers.
