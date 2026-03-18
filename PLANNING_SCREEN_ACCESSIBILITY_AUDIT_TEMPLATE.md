# Planning Screen Accessibility Audit Template (SwiftUI, Phase 1)

Use this template before making Planning screen changes.

Audit metadata:
- Date:
- Auditor:
- Branch/commit:
- Device(s):
- iOS version(s):
- Appearance tested: Light / Dark
- Dynamic Type tested: Default / AX largest
- Assistive settings tested: Reduce Motion / Differentiate Without Color / Increase Contrast
- Scope note: Full VoiceOver copywriting/grouping polish is deferred unless it blocks general usability.

## 1. Screen Purpose
Primary purpose:
- The Planning flow enables users to place, move, edit, and remove protocol allocations across a week while preserving schedule feasibility and clear next actions.

Primary user tasks:
- Understand what to do next in planning.
- Place protocol items into time slots.
- Edit allocation details.
- Edit protocol scheduling rules.
- Resolve empty, invalid, or blocked planning states.
- Apply/discard regulator draft suggestions.

Success criteria:
- Main planning actions remain usable at large text sizes.
- Gesture-heavy interactions (drag/drop, row tap, menus, inline buttons) remain unambiguous.
- State meaning is not color-only.
- Critical readability and action discoverability pass in both light and dark appearance.

## 2. UI Inventory
Mark each item `In Scope` / `Out of Scope` for this audit run.

### A) Entry and routing context
- [x] `LockedIn/Features/AppShell/Views/MainAppView.swift` (tab host, Planning tab entry)
- [x] `LockedIn/Core/Navigation/AppRouter.swift` (Planning focus/edit intents)

### B) Planning screen and subviews
- [x] `LockedIn/Features/Plan/Views/PlanScreen.swift` (primary target)
- [x] `PlanScreen.planBoardSection` (board hierarchy, day/slot cards, hinting)
- [x] `PlanScreen.queueSection` + `queueCard` (queue cards, row tap/menu/drag)
- [x] `PlanScreen.weekPillars` + `dayColumn` + `slotCard` (dense timeline)
- [x] `PlanScreen.todayAtGlanceSection` / `distributionStatus` / `legend`
- [x] `PlanScreen.calendarConnectionBanner`
- [x] `PlanScreen.planToastView`

### C) Planning edit/modals in same file
- [x] `PlanRegulatorSheet`
- [x] `PlanAllocationEditorSheet`
- [x] `ProtocolSchedulingEditorSheet`
- [ ] `ProtocolIconPickerSheet` usage path [VERIFY]

### D) View-model/state dependencies to verify with UI behavior
- [x] `LockedIn/Features/Plan/ViewModels/PlanViewModel.swift` (state and mutation mapping)
- [x] `LockedIn/Features/Plan/Models/PlanModels.swift` (status/date/slot labels, availability)

### E) Interaction patterns present in Planning (explicitly audit)
- [x] Drag/drop (`.draggable`, `.dropDestination`)
- [x] Row tap + inline `Button` + `Menu` on same visual row
- [x] Horizontal scroll + mode toggles (`focusToday` / `expandedWeek`)
- [x] Sheet stack (editor/regulator/profile/icon picker)
- [x] Toast + warning overlays
- [X] Swipe actions [VERIFY]
- [x] Expand/collapse sections [VERIFY]

## 3. Risks
### Information hierarchy risks
- Dense board plus queue plus metrics can bury the primary action path.
- Users may not identify the next action when queue state and board state conflict.

### Dynamic Type and layout risks
- Frequent fixed-size fonts and fixed geometry can clip or compress at AX sizes.
- One-line labels in queue cards, chips, and slot rows can truncate critical details.

### Tap target and gesture risks
- Small icon controls and compact chips may fall below `44x44` hit area.
- Mixed interaction models (row tap + menu + drag + inline button) can cause accidental triggers.

### State communication risks
- Statuses like `PAUSED`, `SKIPPED`, `FULL`, `UNAVAILABLE`, `DRAFT`, and structure states can be inferred mostly from color/tint.
- Calendar connection and warning states can be visually clear but semantically weak.

### Contrast and appearance risks
- Secondary text over gradients/glass may drop below usable contrast, especially in dark mode.
- Low-opacity semantic text may become unreadable in layered backgrounds.

### Reduced motion risks
- Board entrance, pulse effects, and transition animations may still communicate state primarily through motion.

### Modal flow risks
- Multiple sheet entry points can create unclear return paths and context loss.
- Confirm/destructive actions may be visually present but not clearly prioritized.

### Empty/loading/error risks
- Empty queue/empty protocol states may not communicate a clear next step.
- Validation errors in editing sheets may be visible but easy to miss.

## 4. Required Checks
Mark each as `Pass` / `Fail` / `N/A`. Add evidence for each `Fail`.

### A) Primary task clarity and hierarchy
- [Not really clear, it looks abit complicated] Within first viewport, user can identify the next planning action without reading decorative metrics.
- [N/A] Action precedence is explicit: place/edit/remove workflows appear before secondary analytics.
- [Fail] In conflicted states (no queue items, full slots, disconnected calendar), next step is explicit in text.

Common failures:
- Board appears visually rich but user cannot determine next action.
- KPI/status sections dominate above actionable controls.

### B) Dynamic Type resilience (Phase 1 critical)
- [Agent should check] At AX largest text size, no critical planning text is clipped or overlapped in:
  - `planBoardHeader`
  - `queueCard`
  - `slotCard` (compact + expanded)
  - `PlanAllocationEditorSheet`
  - `ProtocolSchedulingEditorSheet`
- [Agent should check] Critical labels wrap/expand vertically instead of shrinking via `minimumScaleFactor`.
- [Agent should check] Main action path (place/edit/move/remove) remains reachable and readable at large text sizes.

SwiftUI implementation notes:
- Prefer semantic text styles (`.headline`, `.subheadline`, `.caption`) for critical copy.
- Use `@ScaledMetric` for fixed geometric values that gate readability/tap size.
- Use `.fixedSize(horizontal: false, vertical: true)` for multi-line critical labels when needed.

Common failures:
- `lineLimit(1)` truncates protocol titles and state tokens.
- Fixed chip heights hide status text at large text sizes.

### C) Tap targets and spacing
- [Agent should check] Every tappable control meets a minimum `44x44` interactive area.
- [Agent should check] Compact controls preserve visual size but expand hit area via padding/content shape.
- [Agent should check] Adjacent actions have enough spacing to prevent accidental adjacent activation.

SwiftUI implementation notes:
- Use `.contentShape(Rectangle())` or rounded shape aligned to visual bounds.
- Expand interaction area with transparent padding, not oversized icons.

Common failures:
- `Menu`/ellipsis controls and plus controls are visually and interactively too small.
- Slot chip action and row action overlap in compact cells.

### D) Interaction ambiguity (row tap vs inline action vs gesture)
- [Agent should check] For each interactive row/card, one primary action is mapped to row tap.
- [Agent should check] Secondary actions are explicit controls with distinct hit areas.
- [Agent should check] Drag/reorder gesture does not accidentally trigger row selection/edit action.
- [Agent should check] Tap-to-place and drop-to-place semantics do not conflict in the same slot.

SwiftUI implementation notes:
- Prefer semantic `Button` for row primary action instead of competing `.onTapGesture`.
- Keep draggable affordances separate from destructive/edit actions.

Common failures:
- Tapping near drag handle opens editor instead of starting drag.
- Card tap and menu button both trigger due to shared gesture region.

My notes:
- i think the non assigned protocls should be at the top, not at the bottom.
- there is a problem with scrolling as you can scroll horizontally for the plan but vertically for the screen, and they mix up quite often, i want that to be buch easier for the user
- and i think the text and font size and the componenets in the plan are small


### E) Add/Edit/Delete and state transitions
- [ should be better] Add/place flow provides deterministic feedback for success and failure.
- [ should be better] Edit flow preserves context and returns to meaningful location after dismissal.
- [ should be better] Delete/remove actions are explicit and not gesture-hidden only.
- [ should be better] Undo action is discoverable when mutation is reversible.

Common failures:
- Removal only available in low-discoverability context menu.
- Toast appears but does not clearly communicate what changed.

### F) Calendar/date/time representations
- [pass] Day and slot labels are unambiguous (no confusing abbreviations).
- [ can be better] Time range text remains readable in narrow or large-text layouts.
- [ agent should check] Calendar connection state includes explicit textual token, not status dot only.

Common failures:
- Day labels collapse into ambiguous short forms.
- Busy-event time strings clip at AX text sizes.

### G) Empty, loading, and error states
- [Fail] Empty queue and no-protocol states include concrete next action text.
- [Fail] Error/validation messages are placed near the relevant action and persist long enough to act.
- [Fail] Overlay warnings do not hide critical controls without an alternative path.

Common failures:
- Empty state copy is informational only, no action guidance.
- Validation error appears below fold in modal form.

### H) State communication without color-only reliance
- [Fail] Every critical state uses at least one non-color reinforcement (text token/icon/shape/pattern).
- [Fail] Slot availability and structure status are understandable in grayscale or low-saturation perception.
- [Fail] Disabled/paused/skipped states are explicit in text, not opacity-only.

Common failures:
- `fragile`/`unstructured` only conveyed by hue change.
- `UNAVAILABLE` and `AVAILABLE` distinguished primarily by tint.

### I) Contrast and appearance robustness
- [Not sure] Critical text meets readability thresholds in both light and dark mode over gradients/glass.
- [Not sure] Secondary text uses opacity floors that remain legible on layered backgrounds.
- [Not sure] Warning, destructive, and actionable text remains legible in recovery theme variants.

Common failures:
- Secondary labels on glass cards fade into background in dark mode.
- State badges rely on low-opacity text over saturated fills.

### J) Reduced Motion behavior
- [Fail] Motion-heavy transitions are gated when Reduce Motion is enabled.
- [Fail] No critical state meaning is conveyed only through animation.
- [Fail] Reduced Motion path still preserves state-change clarity.

SwiftUI implementation notes:
- Gate with `@Environment(\.accessibilityReduceMotion)`.
- Use `.animation(reduceMotion ? .none : ...)` and `.transaction` overrides for key transitions.

Common failures:
- Pulse/entrance animations still run at full intensity with Reduce Motion on.
- Lock-in/placement feedback becomes unclear when animation is removed.

### K) Modal/sheet/alert flow integrity
- [Agent should check] Each sheet has one clear primary action and one clear dismissal path.
- [Agent should check] Destructive actions are explicit and safely separated from primary save/apply actions.
- [Agent should check] Nested sheet flows do not strand users or lose editing context.

Common failures:
- `Done`, `Cancel`, and `Save` semantics conflict or duplicate.
- Icon picker dismissal loses unsaved editor changes unexpectedly.

### L) Nutrition Label relevance (Phase 1 scope)
- [Agent should check] Larger Text: common Planning tasks pass in AX largest text.
- [Agent should check] Sufficient Contrast: critical Planning content is readable in both appearances.
- [Agent should check] Differentiate Without Color: state meaning remains clear without hue cues.
- [Agent should check] Reduced Motion: Planning remains understandable when motion is reduced.
- [Agent should check] Dark Interface: no task-critical regressions in dark appearance.

Phase 1 defer note:
- VoiceOver/Voice Control readiness is tracked but not marked Ready in this pass unless a critical usability blocker is found.

## 5. Fail Examples
Record concrete failures before code changes.

### P0 (blocker)
- [ ] User cannot complete core planning path (place/edit/remove) at AX largest text.
- [ ] Tap target conflict causes wrong action in main flow (e.g., row tap vs menu vs drag).
- [ ] State meaning is lost without color in task-critical decision points.

### P1 (high impact)
- [ ] Calendar/status/slot messages truncate or clip at large text.
- [ ] Low contrast secondary or warning text impairs readability in either appearance.
- [ ] Reduce Motion still produces motion-heavy transitions affecting comprehension.

### P2 (polish)
- [ ] Dense sections reduce scanability but do not block task completion.
- [ ] Non-critical labels remain visually noisy or ambiguous.

Failure log:
- File/path:
- View/component:
- Repro steps:
- Observed behavior:
- Expected behavior:
- Severity: P0 / P1 / P2
- Suggested minimal SwiftUI fix:
- Candidate shared rule/component update: Yes / No

## 6. Definition of Done
A Planning Phase 1 accessibility/usability audit is complete only when all are true:
- UI Inventory is fully scoped with explicit `In Scope` / `Out of Scope` decisions.
- All Required Checks are marked `Pass` / `Fail` / `N/A` with evidence.
- All P0 and P1 issues are documented with exact file/component locations.
- Main planning path (identify next task, place, edit, remove) is validated at AX largest text in light and dark mode.
- Gesture ambiguity risks are explicitly tested and logged.
- Reduced Motion, color-differentiation, and contrast checks are completed for critical states.
- Phase 1 defer scope is documented (full VoiceOver optimization postponed unless critical blocker).

Final gate:
- `READY FOR IMPLEMENTATION`: no unknowns in main Planning action path; P0/P1 issue list is actionable.
- `NOT READY`: missing scope coverage, missing evidence, or unresolved blocker ambiguity.

Audit outcome:
- Status: READY FOR IMPLEMENTATION / NOT READY
- Open P0 count:
- Open P1 count:
- Open P2 count:
- Notes:
