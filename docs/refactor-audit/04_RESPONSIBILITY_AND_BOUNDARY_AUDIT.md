# 04 Responsibility and Boundary Audit

## Purpose and scope
This document maps where responsibilities actually live today across presentation, orchestration, domain, and persistence layers.
It identifies wrong-layer placement and ownership overlap based on direct code evidence.

## Summary
Boundary enforcement is weak. Views and ViewModels execute orchestration that should be centralized, while Stores mix domain behavior, persistence I/O, UI warning lifecycles, and reporting projections.

- Overall severity: **Critical**
- Overall confidence: **High confidence**

## Responsibility map (current state)
| Responsibility | Actual owner(s) | Evidence |
|---|---|---|
| Global flow orchestration (recovery popup, daily check-in popup, tab selection interactions) | `MainAppView` + `AppRouter` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:73-180,255-330`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift:5-45` |
| Domain write operations for protocol completion + reconciliation | `CockpitView` and `DailyCheckInViewModel` invoke multi-store chain | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:353-360`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:196-204` |
| Plan validation + allocation mutation + persistence + projection + warnings | `PlanStore` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:116-1227` |
| Commitment policy + mutation + recovery transitions + persistence + logs aggregation | `CommitmentSystemStore` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:95-847` |
| Profile/settings persistence for check-in prompt | `ProfilePlaceholderView` and `MainAppView` via `@AppStorage` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift:5-6,136-156`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:48-53` |
| Onboarding transition timing | `OnboardingCoordinator` (timer via `DispatchQueue.main`) | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift:115-121` |

## Findings

### Finding RB-01: UI layer is doing orchestration and domain writes
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **Bug risk**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:345-431` (`perform(_:)` mutates commitment store, plan store, routing, haptics, UI error/toast).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:255-330` (policy prompt evaluation and persistence flag writes in shell view).
- Interpretation:
  - Presentation layer is not just rendering; it executes business flow control and state mutation chains.
- Future implication:
  - Any UI-level change can alter domain behavior. Regression risk is high because no boundary limits side effects.

### Finding RB-02: Stores are overloaded with mixed responsibilities
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **Maintainability risk**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:188-206,424-562,705-965,1094-1227`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:302-330,339-385,458-534,628-654`.
- Interpretation:
  - Both stores combine domain logic, persistence, projection building, and UI-facing message behavior.
- Future implication:
  - Changes become shotgun surgery across unrelated concerns; splitting safely later will be difficult without behavior lock tests.

### Finding RB-03: ViewModel boundary is mostly a pass-through in Plan, but a mini-orchestrator in DailyCheckIn
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Code smell**, **Architecture risk**
- Evidence:
  - `PlanViewModel` mirrors `PlanStore` state via Combine sinks (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:79-115`).
  - `DailyCheckInViewModel` performs completion writes, reconciliation, regulator invocation, and router navigation (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:187-340`).
- Interpretation:
  - ViewModel role is inconsistent across features; there is no stable responsibility contract.
- Future implication:
  - Refactor sequencing is harder because each feature uses a different VM pattern.

### Finding RB-04: Persistence decisions are leaking into startup and debug paths
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Production risk**, **Architecture risk**
- Evidence:
  - Startup clears data behind one-time flags in app root (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-95`).
  - Dev controller directly wipes stores + UserDefaults (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:31-43,310-329`).
- Interpretation:
  - System behavior depends on startup flags and debug mutators in app runtime context.
- Future implication:
  - Relaunch behavior and production initialization become fragile and difficult to reason about.

### Finding RB-05: Domain rule computation is duplicated in feature ViewModels
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **Architecture risk**
- Evidence:
  - Reliability scoring in Cockpit VM (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:162-189`).
  - Different reliability scoring in DailyCheckIn VM (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:434-456`).
- Interpretation:
  - Same concept (reliability) has multiple formulas in presentation layer.
- Future implication:
  - Users can see contradictory scores between screens.

### Finding RB-06: “Manager/Store as protocol boundary” is weakly enforced
- Severity: **Medium**
- Confidence: **Medium confidence**
- Classification: **Code smell**, **Architecture risk**
- Evidence:
  - Direct Store usage from many features instead of narrower use-case interfaces.
  - Example injections: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:13-17`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:15-17`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:13-16`.
- Interpretation:
  - “Store” became a global service locator boundary.
- Future implication:
  - Feature isolation and test doubles are difficult to introduce without broad rewiring.

## Root-cause analysis of responsibility drift
1. Shared mutable global state (`EnvironmentObject` stores) encouraged direct cross-feature mutation.
2. No dedicated orchestration layer for flows (recovery/check-in/plan intent), so orchestration accumulated in Views/VMs.
3. No behavior-level tests to constrain boundary drift; duplicated logic was cheaper than extracting shared rule modules.

## Conclusion
Responsibility ownership is not just blurry; it is structurally collapsed. The codebase currently violates strict layering in multiple directions, with runtime-critical behavior split across UI, ViewModel, and Stores.
