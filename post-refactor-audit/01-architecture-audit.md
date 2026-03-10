# Architecture & Layering Audit

## Scope
This document evaluates feature boundaries, dependency direction, service/repository layering quality, and post-refactor coexistence debt in the current repository state.

## Findings

### LI-001 - Startup reset branch can destructively override persisted user state
- Severity: **Critical**
- Type: **Correctness, Production, Architectural**
- Why it matters:
  - App startup includes a hardcoded one-time reset gate in production path.
  - If the UserDefaults key is absent while JSON files exist, user state is cleared at launch.
- Affected files/types:
  - `LockedInAppRoot`, `RepositoryCommitmentService`, `RepositoryPlanService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-89` (`freshStartResetKey`, `clearAllNonNegotiables()`, `clearAllAllocations()`).
- Recommended fix direction:
  - Move migration/reset behavior behind explicit versioned migrations with idempotent, test-covered guards.
  - Remove destructive reset logic from normal app startup path.
- Confidence: **High**

### LI-004 - `MainAppView` acts as an orchestration layer instead of a presentation shell
- Severity: **High**
- Type: **Architectural, Maintainability**
- Why it matters:
  - Recovery arbitration, daily check-in prompt policy, and cross-feature side effects are owned by a SwiftUI view.
  - This couples UI lifecycle events to business flow decisions and increases regression risk.
- Affected files/types:
  - `MainAppView`, `AppRouter`, `DailyCheckInPolicy`, `RepositoryPlanService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:149-187` (`onAppear` and multiple `onChange` decision entry points).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:262-313` (recovery + daily check-in policy decisions).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:315-338` (AppStorage updates in flow completion handler).
- Recommended fix direction:
  - Introduce an app-shell coordinator/service that owns prompt/recovery arbitration.
  - Keep view layer as rendering + intent forwarding only.
- Confidence: **High**

### LI-005 - Feature modules consume concrete repository services directly
- Severity: **High**
- Type: **Architectural, Maintainability, Testability**
- Why it matters:
  - Concrete service coupling reduces substitution flexibility and keeps refactor boundaries weak.
  - Protocol seams exist but are bypassed in multiple hot paths.
- Affected files/types:
  - `PlanScreen`, `CockpitView`, `DailyCheckInViewModel`, `CreateNonNegotiableView`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:8-13,25-35`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:13-18,30-44`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:14-17,23-27`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift:13`.
- Recommended fix direction:
  - Standardize feature dependencies on protocol abstractions (`PlanService`, `CommitmentActionService`) and keep concrete store/service types inside composition root.
- Confidence: **High**

### LI-012 - Shared-domain service protocol depends on feature presentation models
- Severity: **High**
- Type: **Architectural, Layering**
- Why it matters:
  - `Shared/Domain/PlanService` references `PlanDayModel`, `PlanQueueItem`, and other feature-shaped outputs.
  - Dependency direction is inverted: shared layer depends on feature presentation structures.
- Affected files/types:
  - `PlanService`, `PlanModels`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Domain/PlanService.swift:16-40`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:155-253`.
- Recommended fix direction:
  - Split domain-facing service contract from presentation-facing adapters.
  - Move UI projection models out of shared contracts.
- Confidence: **High**

### LI-011 - Shared UI component depends on app-shell enum defined in a feature view file
- Severity: **Medium**
- Type: **Architectural, Maintainability**
- Why it matters:
  - `Shared/UI/ToastPresenter` takes `AppAppearanceMode`, but `AppAppearanceMode` is declared in `MainAppView.swift`.
  - This creates hidden feature-to-shared coupling and brittle file ownership.
- Affected files/types:
  - `ToastPresenter`, `AppAppearanceMode`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/UI/ToastPresenter.swift:4-6,43-45`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:4-37`.
- Recommended fix direction:
  - Move appearance-mode type to a shared app-settings module or decouple toast style from feature enum.
- Confidence: **High**

### LI-013 - DailyCheckIn layer straddles both concrete stores and abstract services simultaneously
- Severity: **Medium**
- Type: **Architectural, Maintainability**
- Why it matters:
  - The same view model reads from concrete stores and writes through protocol services.
  - This dual path blurs ownership and makes future service refactors harder.
- Affected files/types:
  - `DailyCheckInViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:14-17,33-37`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:57-60,196-202,202-209`.
- Recommended fix direction:
  - Use one dependency style per view model (service contract only), with read models supplied via service/query layer.
- Confidence: **High**

### LI-024 - Repository services still expose store-shaped surfaces (state + commands + projections + persistence side effects)
- Severity: **Medium**
- Type: **Architectural, Maintainability**
- Why it matters:
  - `RepositoryPlanService` and `RepositoryCommitmentService` combine write commands, projection builders, status derivation, and persistence concerns.
  - This mirrors legacy store behavior and limits modularity.
- Affected files/types:
  - `RepositoryPlanService`, `RepositoryCommitmentService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:52-71,666-959`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:32-40,384-845`.
- Recommended fix direction:
  - Split command services from query/projection services.
  - Isolate persistence orchestration from UI-shaping computations.
- Confidence: **High**

### LI-010 - Migration residue and simulation artifacts remain in production repo shape
- Severity: **High**
- Type: **Maintainability, Architectural**
- Why it matters:
  - Coexistence artifacts increase discoverability cost and can mislead future changes.
  - Some files are effectively dead but still part of the mental model.
- Affected files/types:
  - Simulation files, duplicate onboarding content view.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanCompletionReconciliationSimulation.swift`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/RepositorySimulation.swift`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Engines/PlanRegulatorSimulation.swift`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableContentView.swift` (only preview usage found).
- Recommended fix direction:
  - Move simulations to explicit dev/test harness locations or remove.
  - Remove unused duplicate feature views.
- Confidence: **Medium-High** (target-membership not fully revalidated for all build configs).

### LI-026 - Composition root is manual and ad-hoc, without a formal dependency container
- Severity: **Medium**
- Type: **Architectural, Maintainability**
- Why it matters:
  - App root constructs concrete repositories/services inline and injects environment objects globally.
  - As dependency count grows, configuration drift and environment leakage risk increase.
- Affected files/types:
  - `LockedInAppRoot`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:37-57,74-77`.
- Recommended fix direction:
  - Introduce a small composition module/container to centralize service construction and environment wiring.
- Confidence: **High**

## Architecture Quality Verdict
The architecture is in a transitional state: substantially improved versus legacy store concentration, but still carrying important layering leaks and presentation-owned orchestration. The next phase should prioritize hard boundary cleanup and extracting policy flow out of SwiftUI roots.
