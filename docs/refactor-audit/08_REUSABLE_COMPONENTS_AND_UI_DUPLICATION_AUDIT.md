# 08 Reusable Components and UI Duplication Audit

## Purpose and scope
This document identifies repeated UI structures and evaluates which repetitions are benign versus harmful.
Focus is on evidence of repeated containers/modals/cards/forms and missing primitives.

## Summary
UI repetition is high in runtime-critical screens. Some duplication is acceptable for visual variation, but repeated navigation chrome, profile sheets, toast behavior, and modal container patterns are copy-pasted with local state logic.

- Severity: **High**
- Confidence: **High confidence**

## Repetition clusters

### UI-01: Repeated top-bar action cluster (logs bell + profile)
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**, **Maintainability risk**
- Evidence:
  - Cockpit: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:44-85`
  - Plan: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:73-101`
  - Logs: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:61-89`
- Interpretation:
  - Same UI behavior is reimplemented three times with slight style differences.
- Future implication:
  - Navigation-action changes require touching multiple large screens.

### UI-02: Repeated profile sheet presentation pattern
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**
- Evidence:
  - Cockpit `.sheet(isPresented: $showProfile) { NavigationStack { ProfilePlaceholderView() } }`: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:99-112`
  - Plan equivalent: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:103-107`
  - Logs equivalent: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:91-95`
- Interpretation:
  - Repeated modal wrapper with identical ownership semantics.
- Future implication:
  - Modal policy changes (detents/analytics/dismiss handling) will drift.

### UI-03: Repeated transient toast/warning containers with independent timing logic
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **UX flow risk**
- Evidence:
  - Cockpit toast: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:149-167,469-476`
  - Plan toast + undo: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:225-231,1395-1461`
  - DailyCheckIn toast/warning overlay: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift:43-80,87-93`
  - Recovery warning overlay: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Recovery/Views/RecoveryModePopup.swift:46-63`
- Interpretation:
  - Message UI appears standardized visually but behavior is manually duplicated.
- Future implication:
  - Inconsistent dismissal timing and animation behavior across flows.

### UI-04: Repeated nested `NavigationStack` inside sheets
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**
- Evidence:
  - Cockpit create sheet: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:99-112`
  - Plan profile and nested sheet content: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:103-107,1906-2065,2135-2332`
  - Onboarding paywall full-screen flow uses its own full-screen container: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/Views/OnboardingShellView.swift:39-52`
- Interpretation:
  - Flow containers are assembled locally per feature.
- Future implication:
  - Modal stacking and nav-state restoration behavior remains inconsistent.

### UI-05: Harmful duplication in giant views with embedded sub-sheets/forms
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **Maintainability risk**
- Evidence:
  - `PlanScreen` includes multiple embedded sheet structs and form flows in one file (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1891-2396`).
  - `CreateNonNegotiableView` includes icon picker/catalog/recent store and multiple cards in one file (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift:12-1366`).
- Interpretation:
  - Reusable UI primitives are partially present, but higher-level composition is still monolithic.
- Future implication:
  - Any UI evolution in these flows remains high risk due to file complexity.

## Benign vs harmful repetition
| Repetition type | Assessment | Why |
|---|---|---|
| Small style token reuse (`Theme`, color helpers) | Benign | Centralized and low risk |
| Repeated haptic trigger lines | Mostly benign | Low complexity and low business impact |
| Repeated nav/profile sheet wiring | Harmful | Flow ownership drift and modal inconsistency |
| Repeated toast/warning UI + timer logic | Harmful | Behavior divergence and lifecycle race risk |
| Repeated rule-derived labels in multiple screens | Harmful | UI inconsistency tied to business logic duplication |

## Missing primitive signals
1. Shared top-bar action component for Cockpit/Plan/Logs.
2. Shared toast/warning presenter with explicit lifecycle/cancellation semantics.
3. Shared profile modal presenter.
4. Shared “protocol status pill/card row” primitives used by Cockpit, DailyCheckIn, Plan queue.

## Conclusion
UI duplication is not only cosmetic debt. In critical flows, repeated UI structure carries repeated behavior logic, which raises bug and regression risk.
