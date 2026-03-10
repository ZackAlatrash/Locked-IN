# SwiftUI State, Composition & Lifecycle Audit

## Findings

### LI-007 - `PlanScreen` is a monolithic view with mixed UI, routing, and orchestration logic
- Severity: **High**
- Type: **Maintainability, Architectural**
- Why it matters:
  - One view owns rendering, navigation, drag-drop, animation sequencing, warning/toast handling, and routing intent processing.
  - This increases coupling and makes lifecycle bugs hard to isolate.
- Affected files/types:
  - `PlanScreen`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:5-227,229-1643` (single file contains all major responsibilities).
- Recommended fix direction:
  - Split into focused subviews + interaction coordinator + state reducer.
- Confidence: **High**

### LI-035 - Sheet/navigation state is dense and fragile in plan flow
- Severity: **High**
- Type: **Maintainability, UI Correctness**
- Why it matters:
  - Multiple independent sheets and item-based editors increase collision risk and make presentation state difficult to reason about.
- Affected files/types:
  - `PlanScreen`, `PlanViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:98-163` (profile sheet, allocation editor sheet, regulator sheet, protocol editor sheet).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:20-25` (multiple presentation state channels).
- Recommended fix direction:
  - Move to a single presentation state enum per feature flow.
- Confidence: **High**

### LI-004 - AppShell lifecycle handlers perform business-policy decisions in view callbacks
- Severity: **High**
- Type: **Architectural, Maintainability**
- Why it matters:
  - Policy decisions run on `.onAppear` / `.onChange` callbacks, increasing sensitivity to SwiftUI lifecycle behavior.
- Affected files/types:
  - `MainAppView`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:149-187,262-338`.
- Recommended fix direction:
  - Move flow decisions to a dedicated coordinator/service and keep view callbacks as simple dispatch points.
- Confidence: **High**

### LI-033 - Unmanaged delayed work (`DispatchQueue.main.asyncAfter`) is widespread in UI animation flows
- Severity: **Medium**
- Type: **Maintainability, Lifecycle Correctness**
- Why it matters:
  - Delayed blocks are not cancellable on view disappearance, creating risk of stale UI mutation after navigation/state changes.
- Affected files/types:
  - `PlanScreen`, `CockpitModernView`, `CockpitLogsScreen`, `OnboardingCoordinator`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1506-1513,1527-1541`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitModernView.swift:609-631`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:448-477`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift:119-121`.
- Recommended fix direction:
  - Replace with cancellable `Task` handles or timeline-based animation state drivers.
- Confidence: **High**

### LI-034 - Toast/ephemeral state timers use detached sleeps without task lifecycle ownership
- Severity: **Medium**
- Type: **Lifecycle Correctness, Maintainability**
- Why it matters:
  - Timed clear behavior can race with new messages and lacks explicit cancellation policy.
- Affected files/types:
  - `PlanScreen`, `ToastPresenter`, `RepositoryPlanService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1409-1415`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/UI/ToastPresenter.swift:27-34`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:1213-1219`.
- Recommended fix direction:
  - Store cancellable task tokens per message channel and cancel on replacement/disappear.
- Confidence: **Medium-High**

### LI-036 - Repeated refresh triggers can cause unnecessary recomputation in feature views
- Severity: **Medium**
- Type: **Performance, Maintainability**
- Why it matters:
  - Multiple lifecycle triggers refresh same derived state (`onAppear`, publisher receive, simulated clock changes), which can churn large UI trees.
- Affected files/types:
  - `CockpitView`, `PlanViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:100-108`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:115-122,124-143`.
- Recommended fix direction:
  - Debounce or centralize refresh triggers; prefer one source of truth for feature invalidation.
- Confidence: **Medium**

### LI-023 - Domain scoring logic is embedded inside a SwiftUI view (`CreateNonNegotiableView`)
- Severity: **Medium**
- Type: **Maintainability, Domain Placement**
- Why it matters:
  - Reliability scoring policy appears in UI layer and duplicates domain calculator behavior.
  - This invites drift and makes behavior difficult to test in isolation.
- Affected files/types:
  - `CreateNonNegotiableView`, `ReliabilityCalculator`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift:920-951`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Domain/ReliabilityCalculator.swift:4-41`.
- Recommended fix direction:
  - Move all reliability projection logic to shared/domain calculators and consume from view model.
- Confidence: **High**

### LI-013 - DailyCheckIn state ownership is split across concrete stores and abstract services
- Severity: **Medium**
- Type: **Maintainability, Testability**
- Why it matters:
  - View model reads mutable store state directly while issuing mutations via service protocols, creating two state channels.
- Affected files/types:
  - `DailyCheckInViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:14-17,57-60,192-225`.
- Recommended fix direction:
  - Consolidate to protocol-backed query/mutation surfaces and remove direct store access.
- Confidence: **High**

### LI-037 - Some preview composition paths instantiate concrete services directly
- Severity: **Low**
- Type: **Maintainability**
- Why it matters:
  - Preview code that builds concrete services can drift from test harness conventions and obscure lightweight preview intent.
- Affected files/types:
  - `CreateNonNegotiableView_Previews`, `CockpitView` previews.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift:955-966`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:705-717`.
- Recommended fix direction:
  - Prefer explicit lightweight preview fixtures/mocks for deterministic UI previews.
- Confidence: **Medium**

## SwiftUI Quality Verdict
The refactor improved flow separation in places, but SwiftUI layers still own too much orchestration. The core path to improve stability is reducing lifecycle-driven business logic in views and replacing non-cancellable delayed UI work with managed tasks/coordinators.
