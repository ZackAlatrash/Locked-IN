# Component Accessibility Rules (SwiftUI, iOS)

## Purpose
These rules govern shared component accessibility behavior. Components are reusable only after required rules pass.

## Review Format
Each component section has:
- Required Rules (release-blocking)
- Optional Enhancements (non-blocking)
- SwiftUI Implementation Notes
- Common Failure Cases

## 1) Buttons (Text Buttons)
### Required Rules
- Visible button text is the spoken label unless text is ambiguous.
- Disabled state is exposed semantically.
- Hit target is minimum `44x44` pt.

### Optional Enhancements
- Add concise hint only when result is not obvious.

### SwiftUI Implementation Notes
- Use `Button` instead of `onTapGesture` on containers.
- Avoid overriding `.accessibilityLabel` when text is already correct.

### Common Failure Cases
- Custom label conflicts with visible text.
- Small text-button hit target in dense layouts.

## 2) Icon-Only Buttons
### Required Rules
- Must include `.accessibilityLabel("...")`.
- Must include `.accessibilityInputLabels([...])` when aliasing improves voice activation.
- Must expose minimum `44x44` pt hit target.

### Optional Enhancements
- Add one alternate input alias for common phrasing.

### SwiftUI Implementation Notes
- Use action-focused names, not symbol names.
- Example inferred labels: `"Open settings" [VERIFY]`, `"Share progress" [VERIFY]`.

### Common Failure Cases
- Missing label.
- Label reads symbol intent incorrectly (e.g., "Square and arrow up").

## 3) Cards (Tappable/Informational)
### Required Rules
- Tappable card must expose one coherent tap target and role.
- Informational card must have deterministic reading order.
- Card states must not rely on color only.

### Optional Enhancements
- Add custom actions for secondary tasks on dense cards.

### SwiftUI Implementation Notes
- Use `.accessibilityElement(children: .combine)` for concise spoken output when appropriate.

### Common Failure Cases
- Duplicate spoken title/subtitle due to nested elements.
- Multiple conflicting tap targets inside one card.

## 4) Banners and Toasts
### Required Rules
- Critical banners must announce when displayed.
- Dismiss action must be accessible and labeled.
- Meaning must be conveyed by text/icon plus color.

### Optional Enhancements
- Add action shortcuts as custom accessibility actions.

### SwiftUI Implementation Notes
- Post announcement on appearance for time-sensitive status.

### Common Failure Cases
- Auto-dismissed critical banner with no announcement.
- Unlabeled close icon.

## 5) Toggles and Selection Controls
### Required Rules
- Use native selection controls (`Toggle`, `Picker`) unless a strong blocker exists.
- Current state/value must be spoken correctly.
- Group label must describe controlled setting.

### Optional Enhancements
- Add grouped summaries for large settings sections.

### SwiftUI Implementation Notes
- For custom controls, provide equivalent semantics with representation/value/action.

### Common Failure Cases
- Custom switch with no on/off semantics.
- Ambiguous setting names with no context.

## 6) Progress Indicators
### Required Rules
- Determinate progress must expose numeric or percentage value.
- Indeterminate progress must include contextual loading text.
- Completion/failure must be announced.

### Optional Enhancements
- Add elapsed/remaining context for long-running tasks.

### SwiftUI Implementation Notes
- Pair `ProgressView` with clear surrounding status text.

### Common Failure Cases
- Spinner only, no spoken context.
- Completion shown visually but never announced.

## 7) Empty States
### Required Rules
- Must include clear title, explanation, and next action.
- Decorative visuals must not pollute spoken output.

### Optional Enhancements
- Add context-aware recovery actions.

### SwiftUI Implementation Notes
- Mark decorative artwork as hidden from accessibility.

### Common Failure Cases
- Empty state with no path forward.
- Illustration announced as irrelevant content.

## 8) Sheets and Full-Screen Covers
### Required Rules
- Focus lands on meaningful content when presented.
- Dismiss control is explicit, labeled, and reachable.
- Focus returns to invoker on dismissal.

### Optional Enhancements
- Add named accessibility actions for common modal commands.

### SwiftUI Implementation Notes
- Use explicit focus state when default focus behavior is insufficient.

### Common Failure Cases
- Background remains navigable while sheet is active.
- Close action exists visually but lacks semantic label.

## 9) Alerts and Confirmations
### Required Rules
- Alert text must communicate consequence and action clearly.
- Destructive action labels must be explicit.
- Action ordering must minimize accidental destructive confirmation.

### Optional Enhancements
- Add additional clarification for irreversible actions.

### SwiftUI Implementation Notes
- Prefer task-specific verbs over generic labels (avoid "OK" for destructive confirmations).

### Common Failure Cases
- Generic button labels hide action impact.
- Critical warning lacks explicit consequence text.

## 10) Tabs and Navigation
### Required Rules
- Tab labels must be stable and meaningful.
- Selected tab state must be conveyed semantically.
- Back/navigation controls must have unambiguous names.

### Optional Enhancements
- Add input aliases where tab names are long.

### SwiftUI Implementation Notes
- Keep tab naming consistent with visible copy and Voice Control commands.

### Common Failure Cases
- Tab names vary per state with no user-facing rationale.
- Icon-only nav controls missing labels.

## 11) Forms and Inputs
### Required Rules
- Every field has a visible label.
- Validation errors are attached to relevant fields and announced.
- Required vs optional is explicit.

### Optional Enhancements
- Add inline examples for complex formats.

### SwiftUI Implementation Notes
- Do not use placeholder as the only accessible label.

### Common Failure Cases
- Error represented only by red border.
- Input intent ambiguous without persistent label.

## 12) Chips, Tags, and Badges
### Required Rules
- Semantic meaning must be available via text/icon, not color alone.
- Selected/active status must be announced.

### Optional Enhancements
- Add grouped summaries when many chips are present.

### SwiftUI Implementation Notes
- Ensure active state uses traits/value and not only styling.

### Common Failure Cases
- Status chips differ by hue only.
- Selection visually obvious but not spoken.

## Definition of Done (Shared Component)
A component is complete only when:
- All required rules for its type pass.
- VoiceOver label/value/traits are validated.
- Voice Control can activate the component by name or number.
- Hit area meets `44x44` pt minimum.
- Dynamic Type, dark mode, and reduced motion checks pass.

## Do Not Do This (Anti-Patterns)
- Do not hide critical actions behind swipe-only gestures.
- Do not create custom controls without semantic equivalents.
- Do not expose duplicate nested accessibility elements by default.
- Do not use icon-only interactions without labels.
