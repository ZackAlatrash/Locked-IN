# Logs Screen Accessibility Audit Template (SwiftUI, Phase 1)

Use this template before making Logs screen changes.

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
- The Logs screen is a diagnostic history surface that helps users understand adherence, completion/violation patterns, and recent timeline events.

Primary user tasks:
- Read current adherence/integrity state.
- Scan trend metrics and matrix/timeline history.
- Interpret date/time grouping and chronology correctly.
- Open related destinations (profile/log context) without losing place.

Success criteria:
- First viewport makes clear what users should notice first.
- Timeline/history rows remain readable and operable at large text sizes.
- State and severity are understandable without color-only cues.
- Empty history and other non-happy paths provide clear guidance.

## 2. UI Inventory
Mark each item `In Scope` / `Out of Scope` for this audit run.

### A) Entry and routing context
- [x] `LockedIn/Features/AppShell/Views/MainAppView.swift` (Logs tab host)
- [x] `LockedIn/Features/Cockpit/Views/CockpitView.swift` (Logs entry from Cockpit)

### B) Logs screen (primary target)
- [x] `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift`
- [x] Top header + toolbar actions
- [x] Integrity matrix card (`28-day matrix`)
- [x] Performance cards (`Deep Focus`, `Neural Sync`)
- [x] Session history rows and empty state
- [x] Legend/state explanation tokens

### C) Supporting model/data mapping that affects readability/state
- [x] `LockedIn/Application/CommitmentSystemStore.swift` (`logsGroupedByDay`, `logsCalendarSignals`)
- [x] `LockedIn/Features/Cockpit/Models/CockpitUIModel.swift` [VERIFY usage impact]

### D) Modals/overlays/destinations from Logs
- [x] Profile sheet (`ProfilePlaceholderView`)
- [Not implemented yet] Alerts/confirmation dialogs [VERIFY]
- [Not implemented yet] Destructive flows [VERIFY]

### E) Optional/variant Logs interactions to verify in current build
- [Not implemented yet] Search bar / `.searchable` [VERIFY]
- [Not implemented yet] Filtering controls [VERIFY]
- [Not implemented yet] Sorting controls [VERIFY]
- [Not implemented yet] Swipe row actions [VERIFY]
- [Not implemented yet] Row tap + inline action combinations [VERIFY]

## 3. Risks
### Hierarchy clarity risks
- Dense top section (matrix + pills + metrics) can obscure primary “what to notice first.”
- Timeline relevance may be visually below-the-fold with weak cueing.

### Dynamic Type and density risks
- Logs screen uses many compact text styles/custom fixed fonts; clipping/compression risk is high in matrix, legend, and timeline rows.
- Timeline row metadata (title/time/badge/reason) can truncate in high text sizes.

### List/timeline readability risks
- Chronology can be misunderstood if date/time tokens are too subtle.
- Grouping and order of day/time/context labels may not be obvious.

### Interaction ambiguity risks
- If row taps and inline chips/actions coexist, accidental triggers can increase.
- If future filtering/sorting is added, controls can conflict with row actions in dense headers.

### Empty state risks
- “No sessions logged yet” can be informational-only without a clear next action.

### Destructive action risks
- If delete/clear/reset is introduced, discoverability and confirmation patterns can cause accidental loss.

### Contrast and non-color communication risks
- Matrix and badge semantics rely heavily on fill color, glow, and subtle text.
- Low-opacity secondary text on layered backgrounds may become unreadable.

### Reduced motion risks
- Staggered section/row/metric entrances may reduce clarity if motion is required to understand sequence.

## 4. Required Checks
Mark each as `Pass` / `Fail` / `N/A`. Add evidence for each `Fail`.

### A) Hierarchy and first-notice clarity
- [x] First viewport clearly communicates the primary diagnostic signal (what users should notice first).
- [x] Secondary metrics do not bury the recent history/timeline context.
- [x] Header and section titles establish clear scan order.
i have noticed that the timeline or the logs dont show all previouse one, i want the user to see all of them and even filter and search.

Common failures:
- Users cannot tell whether to read matrix, metrics, or timeline first.
- Critical state cue is visually subtle and missed.

### B) Dynamic Type resilience
- [x] At AX largest text size, no critical text clips/overlaps in: header, matrix legend, metrics, history rows, empty state.
- [x] Important row text wraps/expands vertically instead of shrinking.
- [x] Date/time and badge tokens remain readable and unambiguous.

SwiftUI implementation notes:
- Prefer semantic styles for critical copy (`.headline`, `.subheadline`, `.caption`).
- Use `@ScaledMetric` for fixed geometry that gates readability.
- Avoid `minimumScaleFactor` as the primary fix for critical text.

Common failures:
- Timeline title/time/badge collision in one row.
- Matrix tokens unreadable at large text.

### C) Tap targets and gesture safety
- [Agent should check] Toolbar and inline actions meet 44x44 interactive area.
- [Agent should check] Dense row chips/inline controls maintain non-overlapping hit areas.
- [Agent should check] Row interaction remains deterministic if inline controls are present.

Common failures:
- Icon actions are visually small with small hit area.
- Tap near badge triggers wrong action.

### D) Timeline/history readability and date-time grouping
- [pass but the explanation of the colors in the legend is not clear] Time labels are consistently formatted and readable.
- [fail] Date/day grouping is understandable without relying on color emphasis.
- [Agent should check] History order is clear (most recent first) and communicated by layout.

Common failures:
- Time appears as low-priority metadata and is missed.
- Rows look chronological but ordering is ambiguous.

### E) Filtering/sorting/search (if present)
- [not present at the moment] Filter/sort/search controls have explicit state and selected value visibility.
- [not present at the moment] Control state remains understandable without color-only selection cues.
- [not present at the moment] Result changes are visually obvious and do not hide core timeline context.

Common failures:
- Active filter indicated by tint only.
- Sorting direction is not explicitly labeled.

### F) Empty, loading, and error states
- [agent should check] Empty state explains what is missing and what to do next.
- [agent should check] Any loading transitions avoid silent/ambiguous content swaps.
- [agent should check] Error states (if any) are readable, actionable, and not color-only.

Common failures:
- Empty state has no next-step guidance.
- Placeholder-like state is mistaken for real data.

### G) State communication without color-only reliance
- [fail] Matrix state, badges, and pills include non-color reinforcement (text/token/icon).
- [agent should check] Stable vs recovery meaning remains clear in grayscale/low-saturation perception.
- [can be better] Violation/completion states are explicit in text.

Common failures:
- Matrix meaning depends primarily on color legend memory.
- Badge severity only visible by hue/saturation.

### H) Contrast and appearance robustness
- [agent should check] Critical text is readable over gradients/glass in Light and Dark.
- [agent should check] Secondary text opacity floors remain legible.
- [agent should check] Badge text and micro-labels remain readable in recovery theme variants.

Common failures:
- Low-opacity micro text disappears on bright or dark gradients.
- Matrix labels are readable in one appearance only.

### I) Reduced Motion
- [agent should check] Logs remains understandable with Reduce Motion enabled.
- [agent should check] Motion staging is not required to understand chronology or hierarchy.
- [agent should check] Reduced-motion path avoids disorienting delayed reveals.

Common failures:
- Timeline comprehension depends on staggered animation sequence.
- Section visibility feels inconsistent when motion is reduced.

### J) Modal/sheet/alert integrity
- [agent should check] Profile sheet has clear dismiss path and predictable return focus/context.
- [agent should check] Any alerts/confirmations (if present) are explicit and non-ambiguous.
- [agent should check] Background interactions are blocked appropriately when modal is active.

Common failures:
- Dismiss path unclear.
- Underlying list remains interactable during modal.

### K) Nutrition Label relevance (Phase 1 scope)
- [agent should check] Larger Text: core Logs tasks pass at AX largest text.
- [agent should check] Sufficient Contrast: critical Logs content remains readable.
- [agent should check] Differentiate Without Color: state meaning remains clear without hue cues.
- [agent should check] Reduced Motion: Logs remains understandable with reduced motion.
- [agent should check] Dark Interface: no critical regressions in dark appearance.

Phase 1 defer note:
- VoiceOver/Voice Control readiness is tracked but not marked Ready in this pass unless a critical usability blocker is found.

## 5. Fail Examples
Record concrete failures before code changes.

### P0 (blocker)
- [ ] Core diagnostic interpretation fails at large text (matrix/history unreadable or clipped).
- [ ] Critical state meaning is color-only in task-defining surfaces.
- [ ] Primary Logs actions are not reliably tappable.

### P1 (high impact)
- [ ] Timeline row metadata truncates and removes needed context.
- [ ] Empty state does not guide the user to a next step.
- [ ] Motion/animation sequence obscures chronology comprehension.

### P2 (polish)
- [ ] Information density is high but still technically operable.
- [ ] Micro-label hierarchy can be clearer without changing behavior.

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
A Logs Phase 1 accessibility/usability audit is complete only when all are true:
- UI Inventory is fully scoped with explicit `In Scope` / `Out of Scope` decisions.
- All Required Checks are marked `Pass` / `Fail` / `N/A` with evidence.
- All P0 and P1 issues are documented with exact file/component locations.
- Core Logs tasks (read state, scan history, interpret chronology) are validated at AX largest text in Light and Dark.
- Color-independence and contrast checks are completed for matrix, badges, and timeline rows.
- Reduced Motion behavior is validated for section/row entrances.
- Phase 1 defer scope is documented (full VoiceOver optimization postponed unless critical blocker).

Final gate:
- `READY FOR IMPLEMENTATION`: no unknowns in core Logs task path; P0/P1 issue list is actionable.
- `NOT READY`: missing scope evidence or unresolved blocker ambiguity.

Audit outcome:
- Status: READY FOR IMPLEMENTATION / NOT READY
- Open P0 count:
- Open P1 count:
- Open P2 count:
- Notes:
