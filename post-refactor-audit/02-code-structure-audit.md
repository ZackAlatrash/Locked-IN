# Code Structure & File Organization Audit

## Findings

### LI-007 - Responsibility concentration remains severe in several mega-files
- Severity: **High**
- Type: **Maintainability, Architectural**
- Why it matters:
  - Large files combine UI composition, side effects, policy logic, and utility code, making safe edits difficult.
  - Review and test isolation cost is high.
- Affected files/types:
  - `PlanScreen`, `CreateNonNegotiableView`, `RepositoryPlanService`, `CockpitLogsScreen`.
- Evidence:
  - File sizes measured from repository:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift` (1643 LOC)
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift` (1366 LOC)
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift` (1221 LOC)
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift` (997 LOC)
- Recommended fix direction:
  - Extract cohesive submodules: view sections, interaction handlers, policy evaluators, and persistence orchestration helpers.
- Confidence: **High**

### LI-010 - Refactor migration artifacts and dead variants are still present
- Severity: **High**
- Type: **Maintainability**
- Why it matters:
  - Residual simulation and duplicate files create false affordances and increase cognitive load for maintainers.
- Affected files/types:
  - Simulation artifacts and unused duplicate onboarding content view.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/RepositorySimulation.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanCompletionReconciliationSimulation.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Engines/PlanRegulatorSimulation.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableContentView.swift` (no call-sites outside preview).
- Recommended fix direction:
  - Move simulation files under explicit non-production harness structure or delete.
  - Remove unused duplicate onboarding content file.
- Confidence: **Medium-High**

### LI-018 - Onboarding model contains unused fields and stale validation reason
- Severity: **Medium**
- Type: **Maintainability, Readability**
- Why it matters:
  - Data model implies flow requirements that are no longer enforced.
  - Future maintainers may implement against stale assumptions.
- Affected files/types:
  - `OnboardingData`, `ValidationReason`, `OnboardingCoordinator`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Models/OnboardingData.swift:24-27,46`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift:106-108`
  - Repository search only finds these symbols in the above files.
- Recommended fix direction:
  - Remove unused onboarding fields/reasons or reintroduce explicit usage with tests.
- Confidence: **High**

### LI-027 - Conversion/helper duplication across files increases drift risk
- Severity: **Medium**
- Type: **Maintainability**
- Why it matters:
  - The same mapping logic is repeated in multiple files, inviting inconsistency.
- Affected files/types:
  - `PlanViewModel`, `DailyCheckInViewModel`, `RepositoryPlanService`.
- Evidence:
  - Plan slot and regulation conversion logic:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:583-611`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:456-475`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:1194-1208`
- Recommended fix direction:
  - Centralize cross-domain slot conversion helpers in one module.
- Confidence: **High**

### LI-028 - Open TODO remains in hot UI interaction path
- Severity: **Low**
- Type: **Maintainability**
- Why it matters:
  - Known debt is left in a user-facing flow and can be forgotten.
- Affected files/types:
  - `PlanScreen`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:384` (`//codex TODO move to viewModel`).
- Recommended fix direction:
  - Track in issue backlog with owner and due milestone; remove inline TODO after extraction.
- Confidence: **High**

### LI-022 - Stale reset key appears to be dead migration residue
- Severity: **Low**
- Type: **Maintainability**
- Why it matters:
  - Unused reset keys make operational behavior harder to reason about.
- Affected files/types:
  - `DevOptionsController`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:327` references `didRunProtocolReset20260303`.
  - No active runtime references found outside reset key lists.
- Recommended fix direction:
  - Remove or document as intentionally retained for backward compatibility.
- Confidence: **High**

### LI-020 - AI service boundary appears orphaned and disconnected from current architecture
- Severity: **Medium**
- Type: **Maintainability, Architectural**
- Why it matters:
  - Unused protocol + placeholder implementation suggests an abandoned seam that confuses ownership.
- Affected files/types:
  - `AIServiceProtocol`, `PlaceholderAIService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Services/AIServiceProtocol.swift:13-34,66-84`.
  - Repository search for AI service symbols returned only this file.
- Recommended fix direction:
  - Remove until needed or wire into a real feature behind explicit flags and tests.
- Confidence: **High**

### LI-029 - Test file organization mixes unrelated concerns
- Severity: **Low**
- Type: **Maintainability**
- Why it matters:
  - Test navigation is harder when router tests are embedded in a plan-store test file.
- Affected files/types:
  - `RepositoryPlanServiceBehaviorLockTests.swift`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/PlanStore/RepositoryPlanServiceBehaviorLockTests.swift:227` (`AppRouterPlanRouteIntentLifecycleTests` in PlanStore folder/file).
- Recommended fix direction:
  - Move app-router tests into dedicated routing test file/folder.
- Confidence: **High**

### LI-031 - `PlanModels.swift` mixes domain model, UI model, and infrastructure provider types
- Severity: **Medium**
- Type: **Maintainability, Layering**
- Why it matters:
  - Model file acts as a catch-all; ownership and dependency intent are unclear.
- Affected files/types:
  - `PlanModels.swift`, `AppleCalendarProvider`, `MockPlanCalendarProvider`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:82-253` (plan models and UI projections).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:272-411` (calendar provider interfaces/implementations).
- Recommended fix direction:
  - Split into `PlanDomainModels`, `PlanPresentationModels`, and `PlanCalendarProvider` files.
- Confidence: **High**

### LI-032 - Naming drift still reflects old architecture ("store" semantics in service era)
- Severity: **Low**
- Type: **Readability, Maintainability**
- Why it matters:
  - Mixed naming (`store`, `service`) makes layer intent less clear.
- Affected files/types:
  - `RepositoryCommitmentService`, `RepositoryPlanService`, multiple feature files.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:4` (`CommitmentStoreError`) and service type naming.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:40-41` (`store`, `planStore`).
- Recommended fix direction:
  - Standardize naming conventions (service vs store) and apply incrementally with regression tests.
- Confidence: **Medium-High**

## Structural Verdict
The refactor improved macro-level organization, but structural cleanup is incomplete. The main blockers are mega-files, dead migration leftovers, and mixed ownership boundaries inside large feature/model files.
