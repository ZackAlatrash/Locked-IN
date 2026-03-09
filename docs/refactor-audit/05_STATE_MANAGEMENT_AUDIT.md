# 05 State Management Audit

## Purpose and scope
This document analyzes actual state ownership, mutation points, and propagation paths across critical flows.
It focuses on duplicated state, hidden coupling, lifecycle fragility, and relaunch implications.

## Summary
State is heavily distributed and partially duplicated. The dominant pattern is “global shared mutable state + local UI state + replicated VM state,” which creates synchronization and ordering hazards.

- Severity: **Critical**
- Confidence: **High confidence**
- Pattern evidence baseline: `@Published 80`, `@State 61`, `@EnvironmentObject 24`, `@AppStorage 21` (`docs/refactor-audit/data/pattern_state_counts.txt`).

## State ownership inventory (critical)
| State domain | Current owner(s) | Evidence | Risk |
|---|---|---|---|
| Core commitment system state | `CommitmentSystemStore.system` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:35` | Global mutable dependency across features |
| Plan state and projections | `PlanStore` published set | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:52-62` | High fan-out + recompute coupling |
| Plan presentation state mirror | `PlanViewModel` published mirror | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:6-24,79-115` | Duplicated state source of truth |
| Navigation and modal intents | `AppRouter` + per-screen local state | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift:6-10`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:26-35` | Competing flow control |
| Daily check-in persistence flags | `@AppStorage` in shell + profile editor | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:48-53`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift:5-6` | UI-coupled persisted state |
| Runtime simulation/control state | `AppClock`, `DevRuntimeState` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/AppClock.swift:6-27`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevRuntimeState.swift:6-20` | Global mutation affects all flows |

## Critical flow traces

### SF-01: Completion from Cockpit card
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **Bug risk**
- Evidence:
  - Action entry: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:345-377`.
  - Store mutation: `recordCompletionDetailed` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:95-123`).
  - Plan mutation: `reconcileAfterCompletion` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:365-412`).
  - Integrity side effect: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:360`.
- Interpretation:
  - A single UI action mutates two global stores and triggers downstream recomputation/refresh from multiple subscribers.
- Future implication:
  - Ordering changes can desynchronize summary cards, plan queue, and modal prompts.

### SF-02: Recovery transition and paused allocation sync
- Severity: **High**
- Confidence: **High confidence**
- Classification: **State desynchronization risk**, **UX flow risk**
- Evidence:
  - Recovery entry context from commitment store: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:339-353`.
  - Pause protocol + pause allocations in separate stores: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:137-141`.
  - Finalization on recovery exit from shell: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:169-173,255-263`.
- Interpretation:
  - Recovery state depends on coordinated mutations across two stores with shell-driven follow-up.
- Future implication:
  - Partial failure or missed trigger can leave protocol state and plan allocation status out of sync.

### SF-03: Daily check-in prompt lifecycle
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **UX flow fragility**
- Evidence:
  - Prompt policy + persisted keys in shell: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:267-327`.
  - Prompt settings updated in profile: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift:136-156`.
  - Dev options also mutate same keys: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:226-229,294-297`.
- Interpretation:
  - Prompt behavior depends on distributed key writes in unrelated surfaces.
- Future implication:
  - Relaunch or debug operations can produce prompt behavior that appears random to users.

## Duplicated and brittle state signals

### Finding ST-01: Plan state is duplicated (store + VM)
- Severity: **High**
- Confidence: **High confidence**
- Type: **Code smell**, **Architecture risk**
- Evidence: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:79-115` mirrors `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:52-62`.
- Interpretation: ViewModel is maintaining a second state surface with subscription lag potential.
- Future implication: inconsistent UI render timing and stale reads during rapid mutation.

### Finding ST-02: Derived state stored as mutable UI state in multiple places
- Severity: **Medium**
- Confidence: **High confidence**
- Type: **Code smell**
- Evidence: transient toast/warning states in `PlanScreen` (`:30-31,1395-1421`), `CockpitView` (`:26-27,469-476`), and `DailyCheckInFlowView` (`:45-63,87-93`).
- Interpretation: multiple manual timers manage equivalent transient state semantics.
- Future implication: race-prone cleanup and inconsistent UX timing.

### Finding ST-03: Hidden global coupling via `EnvironmentObject`
- Severity: **High**
- Confidence: **High confidence**
- Type: **Architecture risk**
- Evidence: high usage concentration (`docs/refactor-audit/data/pattern_environmentobject_by_file.txt:1-7`); runtime-critical screens depend on 3-7 environment objects each.
- Interpretation: feature behavior is implicitly bound to app-wide object graph.
- Future implication: feature extraction or isolation refactor will break easily without explicit dependency boundaries.

## Lifecycle fragility and relaunch effects
- `LockedInAppRoot` startup path mutates persisted stores (`clearAllNonNegotiables`, `clearAllAllocations`) based on one-time flags (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-95`).
- State recalculation triggers are spread across `onAppear`, `scenePhase`, simulated time changes (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:96-105`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:142-180`).

## Screens/types requiring deeper Pass C state tracing
1. `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift`
2. `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`
3. `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift`
4. `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift`
5. `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift`

## Conclusion
State flow currently depends on implicit global coupling and duplicated projection layers. The system is vulnerable to ordering bugs and desynchronization under normal UI lifecycle events.
