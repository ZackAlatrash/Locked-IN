# Cockpit Screen Accessibility Audit Template (SwiftUI)

Use this template before making Cockpit changes.

Audit metadata:
- Date:
- Auditor:
- Branch/commit:
- Device(s):
- iOS version(s):
- Appearance mode tested: Light / Dark
- Dynamic Type tested: Default / AX largest
- Assistive tech tested: VoiceOver / Voice Control / Reduce Motion / Increased Contrast

## 1. Screen Purpose
Primary purpose:
- The Cockpit screen is the operational home surface for system state, protocol execution, check-in entry, and navigation to detail diagnostics.

Primary user tasks:
- Read current system status and reliability.
- Review weekly activity and streak status.
- Review active protocol load and per-task state.
- Complete due protocol tasks.
- Open protocol details, logs, profile, and creation flows.
- Trigger daily check-in flow.

Success criteria:
- All primary tasks are operable with VoiceOver and Voice Control.
- Information hierarchy is understandable without color or animation.
- No baseline accessibility blocker exists before changes begin.

## 2. UI Inventory
Mark each item `In Scope` / `Out of Scope` for this audit run.

### A) Cockpit entry and shell wiring
- [x] `LockedIn/Features/AppShell/Views/MainAppView.swift` (Tab host, Cockpit tab, blocking overlays)
- [x] `LockedIn/Features/Cockpit/Views/CockpitView.swift` (screen container, toolbar, navigation, alerts, sheets, toast)
- [x] `LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift` (state mapping: due/done/extra/recovery/suspended)
- [x] `LockedIn/Features/Cockpit/Models/CockpitUIModel.swift`
- [x] `LockedIn/Features/Cockpit/Models/CockpitNavigation.swift`

### B) Main Cockpit content
- [x] `LockedIn/Features/Cockpit/Views/CockpitModernView.swift` (hierarchy, cards, protocol rows, motion behavior)
- [x] `LockedIn/Features/Cockpit/Views/CockpitView.swift` private `CockpitNonNegotiableDetailsSheet`

### C) Routed destinations from Cockpit
- [ ] `LockedIn/Features/Cockpit/Views/WeeklyActivityDetailView.swift`
- [ ] `LockedIn/Features/Cockpit/Views/StreakDetailView.swift`
- [ ] `LockedIn/Features/Cockpit/Views/CapacityDetailView.swift`
- [ ] `LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift`

### D) Related flows opened by Cockpit actions
- [ ] `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift` (opened from toolbar and tab)
- [x] `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift` (opened from Cockpit create action)
- [x] `LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift` (opened from Cockpit check-in action via `MainAppView`)
- [x] `LockedIn/Features/Recovery/Views/RecoveryModePopup.swift` (blocking overlay that can hide Cockpit from accessibility tree)

### E) Cockpit components (verify usage)
- [ ] `LockedIn/Features/Cockpit/Components/CockpitNonNegotiableCard.swift` (appears legacy/unused in current Cockpit path) [VERIFY]
- [ ] `LockedIn/Features/Cockpit/Components/CockpitKpiCard.swift` (appears legacy/unused in current Cockpit path) [VERIFY]

## 3. Risks
### Information hierarchy risks
- Primary status and secondary metrics are visually dense and may be announced in non-task order.
- Monospaced all-caps labels can dominate spoken order if grouping is not controlled.

### Typography and Dynamic Type risks
- Multiple fixed fonts (`.font(.system(size: ...))`) across Cockpit and detail views can break at AX sizes.
- Frequent one-line constraints and `minimumScaleFactor` use can hide overflow defects.

### Touch target and motor risks
- Toolbar icons and protocol completion controls can fall below `44x44` if only visual size is considered.
- Mixed `Button` + `onTapGesture` behavior in rows can create ambiguous hit regions.

### VoiceOver semantics risks
- Icon-only controls require strict labels and input labels.
- Complex cards can cause duplicate spoken content without explicit grouping strategy.
- Progress-like visuals (rings/bars/capsules) may expose weak value semantics.

### Focus and navigation risks
- Multiple destinations (navigation, sheets, alerts, overlays) can create unstable focus return.
- Blocking overlays from app shell can leak underlying focus if not isolated.

### State communication risks
- Completion toasts may be visual-first if no announcement is posted.
- Error alert copy exists, but transition from action to error may not be announced consistently.

### Color reliance and contrast risks
- Recovery vs stable states and badges rely heavily on tint and saturation.
- Dark/light custom gradients and glass overlays can reduce effective contrast.

### Reduced motion risks
- Entrance staging and metric animations are extensive; reduced motion may still leave implied-only state changes.

### Loading/empty/error risks
- Empty states exist in detail/log views; verify they are actionable and semantically complete.
- Cockpit has no explicit loading state UI; placeholder/render transitions can feel like silent loading.

### Modal/sheet/alert risks
- Multiple sheets (`CreateNonNegotiable`, details sheet, profile sheet) and alerts require deterministic focus placement and return.

### Nutrition Label risks
- Claims can be invalid if any one common Cockpit task fails in VoiceOver, Voice Control, Larger Text, Contrast, or Reduced Motion.

## 4. Required Checks
Mark each as `Pass` / `Fail` / `N/A`.

### A) Information hierarchy
- [N/a] The first three VoiceOver announcements communicate: screen identity, system state, and current actionable next step.
- [Pass] Every section header has a clear spoken relationship to its content.
- [N/A] Decorative content does not interrupt task-critical content in reading order.

### B) Typography and Dynamic Type resilience
- [only the title changed size, but the rest of the content stayed the same] All core Cockpit tasks are operable at largest accessibility text size.
- [N/A cause the rest of the text didnt change size] No clipped, overlapping, or unreadable text in Cockpit and routed detail views.
- [N/A cause the rest of the text didnt change size] No primary action disappears at large text; scrolling preserves access.

### C) Touch targets
- [Agent should check] Toolbar actions meet `44x44` minimum interactive area.
- [Agent should check] Protocol row actions (complete/open details) meet `44x44` and do not conflict.
- [Agent should check] Sheet and detail action buttons meet `44x44` and are separated enough to avoid accidental taps.

### D) VoiceOver labels, values, hints, grouping
- [Dont want to do voice over for now, but agent should check] Icon-only buttons have explicit, action-based labels.
- [Dont want to do voice over for now, but agent should check] Controls exposing state expose value/trait semantics.
- [Dont want to do voice over for now, but agent should check] Grouping is intentional: no duplicate announcements for row title/subtitle/status.
- [Dont want to do voice over for now, but agent should check] Hints are present only when they add outcome clarity.

### E) Focus order
- [Pass] Focus path follows visual/task order in Cockpit root.
- [Pass] Focus enters each destination/sheet/alert at a meaningful first element.
- [Pass] Focus returns to triggering element after dismissal.
- [Pass] Background content is not traversable when a blocking modal/overlay is present.

### F) State communication
- [Fail] Completion, extra-log, and error outcomes are communicated semantically, not visually only.
- [Pass] Disabled states (e.g., unavailable protocol actions) are announced as disabled with clear reason.
- [Pass] Recovery/stable state changes are understandable without relying on color.

### G) Color reliance and contrast
- [Pass] Status differences (stable/recovery/suspended/due/done/extra) are understandable without color.
- [Pass but agent should check aswell] Critical text and indicators satisfy contrast thresholds in light and dark mode.
- [Fail but agent should check] Color-only dots/badges/rings have text/icon/semantic backup.

### H) Reduced motion
- [Fail] Entrance animations and metric transitions are reduced when Reduce Motion is enabled.
- [N/A] Critical state transitions remain understandable without animation.

### I) Loading, empty, and error states
- [Fail] Empty states (e.g., no protocols, no history) include clear next action.
- [Fail] Error alerts are announced and actionable.
- [N/A] Any perceived loading transition has semantic status communication when needed.

### J) Modal, sheet, and alert behavior
- [Pass but should be better] `CreateNonNegotiable` sheet traps focus and provides clear dismiss/back path.
- [Pass but should be better] Details sheet supports predictable read order and action discoverability.
- [Pass but should be better] Profile sheet/alerts/daily-check-in/recovery overlays isolate focus correctly.

### K) Nutrition Label relevance (Cockpit task scope)
Evaluate common Cockpit tasks only. Mark `Ready` only when all in-scope Cockpit tasks pass.

- [ ] VoiceOver Ready
- [ ] Voice Control Ready
- [ ] Larger Text Ready
- [ ] Dark Interface Ready
- [ ] Differentiate Without Color Ready
- [ ] Sufficient Contrast Ready
- [ ] Reduced Motion Ready
- [ ] Captions Ready (N/A unless Cockpit task flow includes spoken media)
- [ ] Audio Descriptions Ready (N/A unless Cockpit task flow includes meaning-critical video)

Blocking rule:
- [ ] No label marked Ready if any audited Cockpit task fails for that label.

## 5. Fail Examples
Record concrete failures before making code changes.

### P0 (blocking)
- [ ] VoiceOver cannot complete protocol action due to unlabeled icon-only control.
- [ ] Focus escapes into background while sheet/overlay is active.
- [ ] Primary action is unreachable at largest text size.

### P1 (must fix)
- [ ] Duplicate spoken output in protocol rows due to poor grouping.
- [ ] Status only distinguishable by color (no text/icon semantic backup).
- [ ] Reduced Motion still presents movement-heavy, comprehension-critical transitions.

### P2 (improve)
- [ ] Non-critical decorative elements increase reading noise.
- [ ] Secondary metrics are understandable visually but not semantically rich.

Failure notes:
- File/path:
- View/component:
- Repro steps:
- Observed behavior:
- Expected behavior:
- Severity:

## 6. Definition of Done
A Cockpit screen accessibility pre-change audit is complete only when all are true:
- Every in-scope item in UI Inventory is explicitly marked In Scope/Out of Scope.
- All Required Checks are marked Pass/Fail/N/A with evidence notes.
- All P0 and P1 failures are documented with reproducible steps.
- Nutrition Label relevance is evaluated using audited Cockpit task outcomes.
- Baseline decision is explicit:
  - `READY FOR CHANGES`: no unidentified blocker and risk map is complete.
  - `NOT READY`: unresolved unknown scope or missing evidence.

Pre-change audit outcome:
- Status: READY FOR CHANGES / NOT READY
- Open P0 count:
- Open P1 count:
- Open P2 count:
- Notes:
