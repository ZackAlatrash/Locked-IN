# 13 Navigation Flow and Screen Ownership Audit

## Purpose and scope
This document traces the actual navigation graph and identifies who owns route decisions, modal presentation, and flow transitions.

## Summary
Navigation ownership is fragmented: AppShell owns blocking overlays, individual features own local sheets/destinations, and router intent consumption is manual. This creates modal overlap and flow fragility risk.

- Severity: **High**
- Confidence: **High confidence**

## Visible navigation graph (fact)
1. App start: `LockedInAppRoot` -> `OnboardingShellView` or `MainAppView` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:59-70`).
2. Onboarding flow: step switch in shell + `fullScreenCover` paywall (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Views/OnboardingShellView.swift:39-52,150-210`).
3. Main app flow: `TabView` with three root stacks (`Cockpit`, `Plan`, `Logs`) in `MainAppView` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:78-108`).
4. Global overlays: recovery popup and daily check-in popup controlled at shell level (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:114-132,220-233`).
5. Cockpit local navigation: `.navigationDestination(item:)` + two `.sheet` + `.alert` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:87-148`).
6. Plan local navigation: four `.sheet` in root plus nested `NavigationStack` forms (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:103-168,1906-2332`).
7. Logs local navigation: profile sheet only (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:91-95`).

## Ownership map
| Flow decision | Current owner | Evidence |
|---|---|---|
| Tab switching | `AppRouter.selectedTab` + local `selectedTab` bindings | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:78`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:10` |
| Plan focus/edit deep-link intents | `AppRouter` produces, `PlanScreen` consumes | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift:12-29`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:174-181,1476-1491` |
| Recovery and daily-checkin popup arbitration | `MainAppView` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:73-75,255-306` |
| Daily-checkin -> plan jump | `DailyCheckInViewModel` calling router intent | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:241-244` |
| Cockpit details -> plan editor jump | `CockpitView` calling router intent | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:387-391` |

## Findings

### NV-01: Modal/overlay ownership split between shell and feature screens
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **UX flow risk**, **Architecture risk**
- Evidence:
  - Shell overlays block entire tab content (`MainAppView` blur/scale/hit-testing): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:109-132`.
  - Simultaneously, feature screens declare their own sheets/alerts (`CockpitView`, `PlanScreen`).
- Interpretation:
  - Blocking overlays and per-screen sheets are controlled from different layers.
- Future implication:
  - Higher chance of presentation conflicts and brittle dismissal ordering.

### NV-02: Router intent consumption is manual and timing-sensitive
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **UX flow risk**
- Evidence:
  - Manual consume functions (`consumePlanFocusIntent`, `consumePlanEditIntent`): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Models/AppRouter.swift:17-29`.
  - Consumed in `PlanScreen` after `onAppear`/`onChange` handling: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:174-181,1482,1491`.
- Interpretation:
  - Intent lifecycle is message-like, not transactional.
- Future implication:
  - Duplicate or dropped navigation intents during fast state changes.

### NV-03: Route control is scattered across non-navigation types
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Architecture risk**
- Evidence:
  - `DailyCheckInViewModel` triggers plan routing (`openPlan`): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:243`.
  - `CockpitView` triggers plan edit routing (`openPlanEditor`): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:390`.
  - Shell also auto-opens popups based on policy and state checks (`MainAppView:255-306`).
- Interpretation:
  - Navigation decisions are distributed among shell view, feature view, and feature VM.
- Future implication:
  - Flow reasoning requires cross-file reconstruction for basic user journeys.

### NV-04: Onboarding uses separate full-screen modal model from app shell
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**, **Flow complexity risk**
- Evidence:
  - Onboarding paywall full-screen cover in onboarding shell (`OnboardingShellView:39-52`).
  - Main app uses tab + overlay model (`MainAppView:78-132`).
- Interpretation:
  - Two independent navigation paradigms in one app lifecycle.
- Future implication:
  - Harder to unify analytics/state restoration and routing policy.

## Critical path traces (condensed)
1. Cockpit complete action -> store mutations -> possible router intent -> user may be redirected to plan editor.
2. Daily check-in resolve manually -> `router.openPlan` -> `PlanScreen` consumes focus intent.
3. Recovery popup flow -> pause selection in VM -> store updates + plan pause -> shell reevaluates popup states.

## Areas needing deeper flow tracing
1. Interaction between `MainAppView` overlay gating and `PlanScreen` sheet stack.
2. Intent handling when multiple route events occur before `PlanScreen` appears.
3. Foreground transitions (`scenePhase`) during active overlay/modal presentations.

## Conclusion
Navigation is functional but not coherently owned. Flow control is split between shell, router, views, and view models, creating high fragility for any refactor touching route logic.
