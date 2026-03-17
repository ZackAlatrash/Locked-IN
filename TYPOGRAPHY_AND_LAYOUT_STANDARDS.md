# Typography and Layout Standards (SwiftUI, iOS)

## Purpose
These rules define mandatory typography and layout behavior for accessibility across all modified screens.

## Required Rules

### 1) Text System and Scaling
#### Required
- Use semantic text styles for user-facing text (`.largeTitle`, `.title`, `.headline`, `.body`, `.subheadline`, `.footnote`, `.caption`).
- Do not use fixed font sizes for primary/secondary content.
- Scale non-text visual metrics tied to readability using `@ScaledMetric`.

#### Code Review Checks
- No `.font(.system(size: ...))` for primary copy.
- No static spacing/icon sizes that break at AX sizes.

#### SwiftUI Implementation Notes
- Keep typography in reusable style tokens/modifiers to prevent drift.
- Use `@ScaledMetric(relativeTo: .body)` for spacing, icon size, and control chrome that must scale.

#### Common Failure Cases
- Text styles mixed arbitrarily, destroying hierarchy.
- Header scales but row spacing stays fixed, causing overlap.

### 2) Layout Reflow at Large Text
#### Required
- At largest Dynamic Type accessibility size, content must remain readable and actionable.
- Layout must reflow vertically before shrinking/truncating primary content.
- Primary actions must remain reachable through scroll if not immediately visible.

#### Code Review Checks
- No clipped text in cards/rows/sheets at AX sizes.
- No overlapping controls after scaling.
- No off-screen primary CTA without scroll access.

#### SwiftUI Implementation Notes
- Prefer adaptive stack changes and `ViewThatFits` over text compression.
- Avoid fixed-height containers for variable content.

#### Common Failure Cases
- `HStack` with fixed widths truncating action labels.
- Hard-coded card height clipping multiline text.

### 3) Tap Geometry and Density
#### Required
- Interactive hit region is minimum `44x44` pt.
- Adjacent interactive controls remain separable at large text sizes.
- Dense layouts must not cause accidental activation.

#### Code Review Checks
- Verify icon-only and trailing controls meet target size.
- Verify row actions are not visually or semantically collapsed.

#### SwiftUI Implementation Notes
- Enforce hit areas with frame and `contentShape(Rectangle())` when visual size is smaller.

#### Common Failure Cases
- Toolbar icons sized visually to ~24pt with no hit-area expansion.
- Multiple small trailing actions in list rows with overlapping tap zones.

### 4) Color, Contrast, and Theme Behavior
#### Required
- Text contrast minimum: `4.5:1` (normal), `3:1` (large).
- Non-text critical indicators: `3:1` minimum where applicable.
- All critical states are understandable without color.
- Light and dark mode both preserve readability and affordances.

#### Code Review Checks
- Validate text contrast in both schemes.
- Validate status/error/selection in grayscale or differentiate-without-color mode.

#### SwiftUI Implementation Notes
- Use semantic colors (`Color.primary`, `Color.secondary`, tokenized semantic palette).
- Pair state color with icon/text/shape.

#### Common Failure Cases
- Status badge conveys warning only via yellow fill.
- Dark mode card border disappears, hiding tap affordance.

### 5) Motion and Visual Stability
#### Required
- Reduce Motion disables/simplifies non-essential movement.
- Core state changes remain explicit without animation.
- Layout remains stable during async state transitions.

#### Code Review Checks
- Toggle Reduce Motion and verify all critical transitions.
- Verify loading completion/error readability with motion reduced.

#### SwiftUI Implementation Notes
- Gate animations via `@Environment(\.accessibilityReduceMotion)`.
- Prefer opacity/content updates over movement-heavy transitions.

#### Common Failure Cases
- State change only represented by slide/parallax motion.
- Motion persists despite Reduce Motion enabled.

## Optional Enhancements
- Define typography snapshots for every major screen at AX sizes.
- Add reusable layout test harness for text-size extremes.
- Add automated screenshot diff checks for light/dark and large text variants.

## Definition of Done (Typography and Layout)
A screen passes typography/layout only when all are true:
- No clipped, overlapping, or unreadable text at largest accessibility text size.
- Primary actions remain reachable.
- All interactive hit areas satisfy `44x44` pt minimum.
- Contrast and state clarity pass in light and dark mode.
- Reduce Motion preserves comprehension of all task-critical transitions.

## Do Not Do This (Anti-Patterns)
- Do not hardcode font sizes for core text.
- Do not fix container height for dynamic text content.
- Do not solve overflow with global `minimumScaleFactor`.
- Do not rely on color-only chips, dots, or borders for status.
- Do not keep dense control spacing unchanged at large text sizes.
