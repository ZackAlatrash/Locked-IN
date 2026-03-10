# Prioritized Remediation Plan

## Planning Assumptions
- Target: production-grade reliability and maintainability without feature expansion.
- Order prioritizes user data safety and regression risk reduction first.
- Each action maps to findings in this audit pack.

## Critical Fixes Before Production

### 1) Remove destructive startup reset path and replace with versioned migration
- Findings: **LI-001, LI-055**
- Why now:
  - Direct data-loss risk at startup.
- Direction:
  - Introduce migration version key + migration runner.
  - Add tests for existing-data + missing-key scenarios.
- Risk level: **Critical**

### 2) Implement explicit persistence failure policy (load/save)
- Findings: **LI-002, LI-047, LI-056**
- Why now:
  - Silent failure semantics can corrupt trust and lose data durability.
- Direction:
  - Add typed repository error channel surfaced to app shell.
  - Add corruption quarantine + backup restore fallback.
  - Block destructive mutations when durable save fails.
- Risk level: **Critical**

### 3) Move persistence I/O off main actor
- Findings: **LI-003, LI-043, LI-057**
- Why now:
  - Main-thread I/O is a direct responsiveness and reliability liability.
- Direction:
  - Introduce repository actor/background queue.
  - Keep UI state updates on main actor only.
- Risk level: **Critical**

## High-Value Cleanup Soon (Next Wave)

### 4) Extract app-shell policy orchestration from `MainAppView`
- Findings: **LI-004, LI-059**
- Direction:
  - Create app-shell coordinator/use-case for recovery + check-in arbitration.
  - Add integration tests for orchestration matrix.

### 5) Consolidate duplicated completion/recovery logic into shared domain use-cases
- Findings: **LI-006, LI-019, LI-044**
- Direction:
  - Single source for completion reconciliation + user feedback messages.
  - Remove duplicated recovery completion requirement logic from service layer.

### 6) Enforce clean dependency direction (protocol boundaries + shared type ownership)
- Findings: **LI-005, LI-011, LI-012, LI-013**
- Direction:
  - Stop injecting concrete `Repository*Service` into feature views/view models.
  - Move `AppAppearanceMode` and other cross-cutting types to shared app-settings module.
  - Split `PlanService` into domain-facing and presentation-facing contracts.

### 7) Expand test matrix for production paths
- Findings: **LI-008, LI-052, LI-054, LI-056, LI-059**
- Direction:
  - Add startup/migration tests, file-corruption tests, app-shell integration tests, and UI flow tests.
  - Keep parity/behavior-lock tests but rebalance toward end-to-end confidence.

## Medium Priority Cleanup

### 8) Break mega-files into bounded units
- Findings: **LI-007, LI-031, LI-035**
- Direction:
  - Decompose `PlanScreen`, `CreateNonNegotiableView`, `RepositoryPlanService`, `CockpitLogsScreen`.
  - Move model/provider mixes out of catch-all files.

### 9) Stabilize temporal behavior
- Findings: **LI-009, LI-041, LI-058**
- Direction:
  - Inject reference date into regulator.
  - Define timezone policy and add transition tests.

### 10) Replace non-cancellable delayed UI work with task-owned lifecycles
- Findings: **LI-033, LI-034, LI-038**
- Direction:
  - Use cancellable task handles for delayed animations/toasts.
  - Actor-annotate onboarding coordinator/state objects.

### 11) Improve service contract clarity and initialization guarantees
- Findings: **LI-039, LI-050, LI-051**
- Direction:
  - Remove ad-hoc publisher snapshot patterns.
  - Make service context/bootstrap requirements explicit.
  - Eliminate unused policy context parameters or implement behavior.

## Low Priority Polish

### 12) Remove dead artifacts, stale keys, and naming drift
- Findings: **LI-010, LI-018, LI-020, LI-022, LI-028, LI-029, LI-032**
- Direction:
  - Delete/move simulation files and duplicate views.
  - Remove stale onboarding fields and reset keys.
  - Normalize naming (service vs store) and test file placement.

### 13) Replace placeholder/non-functional settings surfaces
- Findings: **LI-060, LI-061**
- Direction:
  - Implement restore purchases.
  - Gate or complete placeholder profile settings.

## Quick Wins (Low Effort, High Signal)
- Add tests for `freshStartResetKey` startup behavior and disable destructive branch in non-migration runtime path (LI-001, LI-055).
- Replace `print` diagnostics with structured logger in service hot paths (LI-015).
- Remove `CreateNonNegotiableContentView` duplicate and stale TODO in `PlanScreen` (LI-010, LI-028).
- Mark `OnboardingCoordinator` as `@MainActor` (LI-038).
- Implement restore purchases button action contract (LI-060).

## Dangerous Areas (High Change Risk)
- `MainAppView` orchestration (`evaluateRecoveryEntryPresentation`, `evaluateDailyCheckInAutoPresentation`) due multi-trigger lifecycle coupling.
- `RepositoryCommitmentService` recovery transitions and persistence side effects.
- `RepositoryPlanService` refresh/normalization/persistence interplay and context dependency on `lastSystem`.
- Cross-feature completion behavior currently split across Cockpit and DailyCheckIn.

## Areas That Look Clean But Are Deceptively Fragile
- `PlanService` abstraction: appears clean, but currently carries feature presentation models and leaks layering intent (LI-012).
- Date logic utility (`DateRules`) appears simple, but `.current` timezone reliance is globally behavior-defining (LI-041).
- Behavior-lock tests look comprehensive, but do not cover startup, migration, corruption, or UI integration paths (LI-008, LI-056).

## Do-Not-Change-Without-Careful-Regression-Suite Items
- Recovery transition and clean-day logic:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Engines/CommitmentSystemEngine.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift`
- Completion reconciliation in plan allocations:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:374-418`
- App-shell recovery/check-in arbitration:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:262-338`
- Plan placement validation and policy coupling:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:1088-1161`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Policy/CommitmentPolicyEngine.swift:126-157`

## Suggested Execution Sequence
1. Ship safety baseline: LI-001, LI-002, LI-003.
2. Add missing regression suites around startup/persistence/app-shell before deeper structural rewrites.
3. Consolidate duplicated domain flows (completion/recovery) and then split service boundaries.
4. Decompose mega-files after behavior is protected by new tests.
