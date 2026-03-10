# Concurrency & Actor Isolation Audit

## Findings

### LI-003 - Persistence is performed synchronously from `@MainActor` services
- Severity: **Critical**
- Type: **Concurrency, Performance, Production**
- Why it matters:
  - User-driven mutations perform JSON encode/write synchronously on main actor.
  - Under larger payloads, this can block UI and make app responsiveness nondeterministic.
- Affected files/types:
  - `RepositoryCommitmentService`, `RepositoryPlanService`, JSON repositories.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:9-10,625-632`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:50-51,950-953`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:53-67`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:47-61`.
- Recommended fix direction:
  - Move repository I/O to a dedicated actor/background queue with explicit marshaling back to UI state.
- Confidence: **High**

### LI-009 - Regulator engine uses wall clock instead of injected reference time
- Severity: **High**
- Type: **Correctness, Concurrency/Testability**
- Why it matters:
  - Scheduler logic diverges from app clock simulation/testing and can produce inconsistent results across call contexts.
- Affected files/types:
  - `PlanRegulatorEngine`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Engines/PlanRegulatorEngine.swift:15-24` (`todayStart = DateRules.startOfDay(Date(), ...)`).
- Recommended fix direction:
  - Pass `referenceDate` into regulator input and eliminate direct `Date()` reads.
- Confidence: **High**

### LI-038 - `OnboardingCoordinator` mutates published state without actor annotation
- Severity: **Medium**
- Type: **Concurrency, Maintainability**
- Why it matters:
  - Coordinator is an `ObservableObject` with UI state but lacks `@MainActor`, relying on convention rather than enforced isolation.
- Affected files/types:
  - `OnboardingCoordinator`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift:17,21-22,115-121`.
- Recommended fix direction:
  - Mark coordinator and related onboarding shell state objects `@MainActor` and keep transitions actor-safe.
- Confidence: **High**

### LI-039 - Ad-hoc publisher snapshot pattern risks hidden lifecycle/thread assumptions
- Severity: **Medium**
- Type: **Concurrency, Maintainability**
- Why it matters:
  - Pattern subscribes to a publisher, writes to local var, and immediately uses it synchronously.
  - Works today due current publisher semantics; brittle if publisher behavior changes.
- Affected files/types:
  - `PlanViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:136-143,218-223,322-327`.
- Recommended fix direction:
  - Replace with explicit synchronous query API or `async` request API from service.
- Confidence: **Medium-High**

### LI-043 - Calendar fetch is synchronous in refresh path on main actor
- Severity: **Medium**
- Type: **Performance, Concurrency**
- Why it matters:
  - `events(for:)` is called during `refresh` on `@MainActor`, and EventKit query is synchronous.
  - Potential UI stalls when calendar volume is large.
- Affected files/types:
  - `PlanViewModel`, `AppleCalendarProvider`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:124-133`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:329-350`.
- Recommended fix direction:
  - Fetch calendar events off-main with cancellation support and publish results back to main actor.
- Confidence: **Medium**

### LI-033 - UI delayed callbacks are non-cancellable and can outlive relevant state
- Severity: **Medium**
- Type: **Concurrency, Lifecycle Correctness**
- Why it matters:
  - Delayed main-queue closures may execute after state has moved on; race-like UI behavior appears as flicker or stale transitions.
- Affected files/types:
  - `PlanScreen`, `CockpitModernView`, `CockpitLogsScreen`, `OnboardingCoordinator`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1506-1513,1527-1541`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitModernView.swift:609-631`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:448-477`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift:119-121`.
- Recommended fix direction:
  - Use cancellable tasks with explicit lifetime ownership tied to view lifecycle.
- Confidence: **High**

### LI-042 - Repository protocols and implementations are not actor-isolated or sendable-ready
- Severity: **Medium**
- Type: **Concurrency, Future Maintainability**
- Why it matters:
  - Current safety relies on caller (`@MainActor` services), not repository contract itself.
  - Future background writes/reads can introduce data races if done without strict actor boundaries.
- Affected files/types:
  - `CommitmentSystemRepository`, `PlanAllocationRepository`, JSON repository implementations.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/CommitmentSystemRepository.swift:3-6`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/PlanAllocationRepository.swift:3-6`.
- Recommended fix direction:
  - Define explicit isolation model (e.g., repository actors) and encode it in protocol contracts.
- Confidence: **Medium**

### LI-041 - Timezone is read dynamically (`.current`) across date-critical logic
- Severity: **Medium**
- Type: **Correctness, Concurrency/Temporal Stability**
- Why it matters:
  - Week/day computations can shift when device timezone changes, altering planning/compliance outcomes for existing records.
- Affected files/types:
  - `DateRules` and all consumers.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Domain/DateRules.swift:13-17`.
- Recommended fix direction:
  - Define explicit domain timezone policy and persist/derive week boundaries consistently.
- Confidence: **Medium**

## Concurrency/Isolation Verdict
The app is effectively "main-thread by default". That simplifies correctness today but at a significant performance and scalability cost, and it hides isolation assumptions that are not codified in repository contracts. Production hardening should prioritize off-main persistence and explicit actor boundaries.
