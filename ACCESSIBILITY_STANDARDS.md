# Accessibility Standards (SwiftUI, iOS)

## Purpose and Scope
These standards are mandatory for every modified SwiftUI screen.

- Scope: iOS SwiftUI screens and shared SwiftUI components.
- Adoption model: enforce screen-by-screen starting with Cockpit.
- Merge rule: modified screens must meet required rules in this document.

## Project Accessibility Baseline
A screen is incomplete until all baseline items pass.

### Baseline Required Rules (Release Blocking)
- All interactive elements are reachable and operable with VoiceOver.
- All interactive elements are reachable and operable with Voice Control (name or number).
- No primary interactive target is smaller than `44x44` pt.
- Screen is usable at largest Dynamic Type accessibility sizes (no clipped/overlapping/unreachable primary content).
- Critical state is never conveyed by color alone.
- Light mode and dark mode are both fully usable.
- Reduce Motion does not block task completion or state comprehension.
- Critical async state changes (loading complete, error, save success) are announced.

### Baseline Optional Enhancements (Non-Blocking)
- Custom rotors for dense information views.
- Additional Voice Control input aliases for power users.
- Contextual custom accessibility actions to speed repeated tasks.

## Severity and Enforcement
- **P0 (Blocker):** task cannot be completed with assistive technology.
- **P1 (Must Fix):** task is completable but has high-friction accessibility failure.
- **P2 (Improve):** quality enhancement, not release-blocking.

Release gate for modified screens:
- `0` open P0
- `0` open P1
- QA checklist completed and attached to PR

## Required Rules by Section

### 1) Semantic Accessibility (VoiceOver + Voice Control)
#### Required Rules
- Native controls are mandatory for interaction when available (`Button`, `Toggle`, `Picker`, `Slider`, `TextField`, `NavigationLink`).
- Icon-only controls must define `.accessibilityLabel(...)`.
- Icon-only controls must define `.accessibilityInputLabels([...])` when spoken aliases are needed.
- Decorative images must use `.accessibilityHidden(true)`.
- Stateful controls must expose state via traits and/or `.accessibilityValue(...)`.

#### Code Review Checks
- No gesture-only interactive UI without semantic accessibility traits/actions.
- No icon-only button without explicit label.
- No redundant parent/child labels causing duplicate spoken output.

#### SwiftUI Implementation Notes
- Do not add `.accessibilityLabel` to text buttons when visible text is already correct.
- Use `.accessibilityElement(children: .combine/.contain/.ignore)` intentionally to control spoken granularity.
- Mark inferred control names as `[VERIFY]` in standards and PR notes.

#### Common Failure Cases
- `Image(systemName:)` inside a button with no label.
- Nested accessibility elements reading the same title twice.
- Symbol names used as spoken labels instead of user-facing actions.

### 2) Reading Order, Grouping, and Focus Management
#### Required Rules
- Spoken order must match task order.
- Modal surfaces must prevent background traversal while presented.
- Focus must land on a meaningful first element when a new screen/sheet/alert appears.
- Focus must return to the invoking control after dismissal.

#### Code Review Checks
- Read top-to-bottom VoiceOver traversal against visual hierarchy.
- Verify modal focus isolation.
- Verify focus restoration path on close.

#### SwiftUI Implementation Notes
- Use `.accessibilitySortPriority(...)` only to fix verified order issues.
- Use `@AccessibilityFocusState` for deterministic focus entry/return flows.

#### Common Failure Cases
- Banner appears visually but is never announced.
- Sheet opens and VoiceOver starts reading background tabs.
- Dismissing modal drops focus unpredictably.

### 3) Dynamic Type and Layout Reflow
#### Required Rules
- Text must use semantic styles (`.body`, `.headline`, etc.) or equivalent scalable style mapping.
- Non-text dimensions tied to readability must scale via `@ScaledMetric`.
- Largest accessibility text size must preserve task completion.
- Primary actions must remain visible or reachable via scrolling.

#### Code Review Checks
- No fixed-size body text via `.font(.system(size: ...))`.
- No hard frame heights that clip core content at AX sizes.
- No dependency on `minimumScaleFactor` for primary labels.

#### SwiftUI Implementation Notes
- Prefer vertical expansion and scroll over text compression.
- Use adaptive layout changes (`ViewThatFits`, conditional stacks) instead of shrinking text.

#### Common Failure Cases
- CTA clipped at AX sizes.
- Overlapping labels in dense `HStack` layouts.
- One-line truncation of critical content with no alternate path.

### 4) Touch Targets and Motor Accessibility
#### Required Rules
- Interactive hit areas must be at least `44x44` pt.
- Swipe-only critical actions must have a visible and voice-accessible alternative.
- Dense controls must maintain separable hit regions.

#### Code Review Checks
- Hit area verification for icon-only controls and trailing actions.
- Check list rows with multiple actions for accidental-tap risk.

#### SwiftUI Implementation Notes
- Expand tap region with frame/contentShape without changing visual size.
- Prefer explicit controls over `onTapGesture` on non-control containers.

#### Common Failure Cases
- Tiny toolbar icons with no padded hit area.
- Hidden swipe action with no equivalent explicit button.

### 5) Contrast, Dark Mode, and Differentiate Without Color
#### Required Rules
- Text contrast meets `4.5:1` (normal) and `3:1` (large text).
- Essential non-text indicators meet `3:1` where applicable.
- Status and priority are never color-only.
- Screen remains legible and operable in light and dark mode.

#### Code Review Checks
- Validate critical text/background pairs in both modes.
- Validate selected/error/success states with grayscale simulation.

#### SwiftUI Implementation Notes
- Use semantic/system colors and project tokens that map to both schemes.
- Add icon/text/shape cues for every color-coded state.

#### Common Failure Cases
- Red/green only status chips.
- Dark mode text blending into card background.

### 6) Motion and Reduced Motion
#### Required Rules
- Reduce Motion must disable or simplify non-essential movement.
- Task-critical state changes must remain explicit without animation.
- Animations must not be the only channel for change detection.

#### Code Review Checks
- Verify transitions with `Reduce Motion` enabled.
- Confirm completion/error is understandable without animated cues.

#### SwiftUI Implementation Notes
- Gate animation using `@Environment(\.accessibilityReduceMotion)`.
- Use fade/state text updates when motion is reduced.

#### Common Failure Cases
- Progress completion signaled only by animated transformation.
- Spring/parallax effects still active under Reduce Motion.

### 7) State Communication and Announcements
#### Required Rules
- Loading, success, and error states are programmatically exposed.
- Important async updates trigger an announcement.
- Disabled controls expose disabled semantics.

#### Code Review Checks
- Verify announcements for network completion and failure.
- Verify state value is available to assistive technologies.

#### SwiftUI Implementation Notes
- iOS 17+: `AccessibilityNotification.Announcement`.
- Older iOS fallback: `UIAccessibility.post(notification: .announcement, argument: ...)`.

#### Common Failure Cases
- Spinner starts/stops with no spoken context.
- Error appears visually but never announced.

### 8) Media Accessibility (If Media Exists in Core Flows)
#### Required Rules
- Spoken media in task flows must provide captions.
- Visual-only meaning required for comprehension must provide audio descriptions.

#### Code Review Checks
- Verify captions and audio-description availability in tested flows.

#### SwiftUI Implementation Notes
- Prefer media components/workflows that expose system caption and audio-description controls.

#### Common Failure Cases
- Claiming captions support while no caption track exists.
- Claiming audio descriptions without descriptive track availability.

## App Store Accessibility Nutrition Label Readiness (9 Labels)
A label is claimable only when all common tasks in release scope pass for that capability.

1. VoiceOver
2. Voice Control
3. Larger Text
4. Dark Interface
5. Differentiate Without Color
6. Sufficient Contrast
7. Reduced Motion
8. Captions
9. Audio Descriptions

Required rule for claims:
- Any `❌` in a common task blocks claiming that label.
- Use `N/A` only when capability does not apply to app functionality.

## Definition of Done (Screen Accessibility Pass)
A screen passes accessibility only when all are true:
- Project Accessibility Baseline passes fully.
- No open P0/P1 findings on that screen.
- Shared components used by the screen satisfy component rules.
- Manual QA checklist for the screen is complete and attached to PR.
- Any inferred labels are validated and marked `[VERIFY]` in review notes.
- Nutrition label impact is reviewed for changed task flows.

## Do Not Do This (Anti-Patterns)
- Do not ship icon-only controls without explicit labels.
- Do not rely on placeholder text as the only field label.
- Do not communicate state using color only.
- Do not hardcode body text sizes for primary content.
- Do not use `minimumScaleFactor` to hide layout problems.
- Do not put all interaction on non-semantic container gestures.
- Do not announce duplicate or irrelevant accessibility content.
