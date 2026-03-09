# 07 Feature Boundaries and Dependency Audit

## Purpose and scope
This document maps actual feature boundaries, dependency direction, and cross-feature tangles based on code references.
It focuses on runtime ownership and mutation coupling, not folder naming alone.

## Summary
The repository layout is feature-heavy, but runtime dependencies are centralized through shared stores and router intents. Features are not isolated; they are coordinated through global mutable objects.

- Severity: **High**
- Confidence: **High confidence**
- Feature distribution reference: `Onboarding 17`, `Cockpit 14`, `DailyCheckIn 7`, `Recovery 4`, `Plan 3`, `DevOptions 3`, `AppShell 2` (`docs/refactor-audit/data/swift_feature_counts.txt`).

## Feature inventory and ownership
| Feature | Primary screens/types | Actual owner for core behavior |
|---|---|---|
| AppShell | `MainAppView`, `AppRouter` | Owns tab shell + popup gating + prompt timing |
| Cockpit | `CockpitView`, `CockpitViewModel`, `CockpitLogsScreen` | Triggers completion writes, plan reconciliation, tab routing |
| Plan | `PlanScreen`, `PlanViewModel`, `PlanStore` | Owns allocation lifecycle, queue/structure computation, calendar integration |
| DailyCheckIn | `DailyCheckInFlowView`, `DailyCheckInViewModel` | Owns unresolved protocol workflow + regulator path + route into plan |
| Recovery | `RecoveryModePopup`, `RecoveryModeViewModel` | Owns pause-selection flow and cross-store recovery sync |
| Onboarding | `OnboardingShellView`, coordinator + subfeature views | Owns gated onboarding navigation and paywall full-screen flow |
| DevOptions | `DevOptionsView`, `DevOptionsController` | Owns debug-time data wipes and scenario seeding |

## Dependency hotspots

### Hotspot FD-01: Shared global store dependency hub
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Architecture risk**
- Evidence:
  - Widespread `CommitmentSystemStore` usage across app shell, cockpit, plan, daily check-in, recovery, onboarding create flow, dev options.
  - Widespread `PlanStore` usage across app shell, cockpit, plan, daily check-in, recovery, dev options.
  - Examples: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:13-17`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:14-17`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:15-17`.
- Interpretation:
  - Feature modules depend on full system stores, not narrow interfaces.
- Future implication:
  - Any store contract change cascades across many features.

### Hotspot FD-02: Cross-feature completion chain duplicated in Cockpit and DailyCheckIn
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **Architecture risk**
- Evidence:
  - Cockpit chain: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:353-360`.
  - DailyCheckIn chain: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:196-204`.
- Interpretation:
  - Same concept implemented in two feature paths.
- Future implication:
  - Divergent behavior likely when one path changes and the other does not.

### Hotspot FD-03: Router intent model is pseudo-centralized but consumed ad hoc
- Severity: **High**
- Confidence: **High confidence**
- Classification: **UX flow risk**, **Architecture risk**
- Evidence:
  - Router defines pending intents (`pendingPlanFocusProtocolId`, `pendingPlanEditProtocolId`): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift:7-8`.
  - `PlanScreen` consumes and clears intents on appear and change handlers: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:174-181,1476-1491`.
  - `CockpitView` sets edit intent: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:390`.
- Interpretation:
  - Routing is effectively message passing with manual consume semantics.
- Future implication:
  - Lost/duplicate navigation intent bugs are plausible during rapid tab switching.

### Hotspot FD-04: Onboarding contains pseudo-domain scaffolding disconnected from app core flows
- Severity: **Medium**
- Confidence: **Medium confidence**
- Classification: **Code smell**, **Maintainability risk**
- Evidence:
  - `AIServiceProtocol` + `PlaceholderAIService` exist but no real integration points found (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Services/AIServiceProtocol.swift:13-84`; reference search shows no consumers beyond file itself).
- Interpretation:
  - Feature boundary includes placeholders that are not part of production behavior.
- Future implication:
  - Increases conceptual load and obscures real dependencies.

## Dependency direction violations/signals
- Presentation -> store mutation -> persistence is direct in multiple features (missing use-case boundary).
- Recovery VM mutates both commitment and plan stores directly (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:139-141`).
- DevOptions writes into production stores and UserDefaults directly (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:31-43,63-94`).

## Shared code: truly shared vs misplaced
- Truly shared: date math (`DateRules`), policy engine, persistence repository protocols.
- Likely misplaced in feature surfaces:
  - Plan-related domain scoring and load projection in `CreateNonNegotiableView` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift:188-255`).
  - Session release toast rules duplicated in Cockpit and DailyCheckIn.

## Future boundary candidates (for later phases, no refactor now)
1. Single completion orchestration boundary (currently duplicated in Cockpit + DailyCheckIn).
2. Single navigation/flow coordinator for overlay and modal routing (currently split across shell + screens).
3. Store read/write interfaces per feature instead of full-store dependency.

## Conclusion
Folder structure suggests features, but runtime behavior is organized around shared stores and ad hoc router intents. This is a mixed architecture with high coupling and low isolation.
