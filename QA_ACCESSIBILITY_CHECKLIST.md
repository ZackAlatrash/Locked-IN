# QA Accessibility Checklist (SwiftUI iOS)

## Purpose
Use this checklist as a release gate for every modified screen.

## Project Accessibility Baseline (Gate)
A screen fails immediately if any baseline item fails.

### Required Baseline Checks (Blocking)
- [ ] VoiceOver-only completion of all primary tasks
- [ ] Voice Control completion of all primary tasks (name or number)
- [ ] All primary interactive elements meet `44x44` pt target size
- [ ] Largest Dynamic Type accessibility size remains fully usable
- [ ] No critical state communicated by color only
- [ ] Light mode and dark mode both fully usable
- [ ] Reduce Motion preserves task completion and state clarity
- [ ] Critical async updates are announced

### Optional Baseline Enhancements (Non-Blocking)
- [ ] Custom rotor support in complex screens
- [ ] Voice Control aliases for alternate command phrasing
- [ ] Additional custom actions for repetitive workflows

## Test Matrix (Minimum Required)
- [ ] Smallest supported iPhone form factor
- [ ] Largest supported iPhone form factor
- [ ] Lowest supported iOS version for release
- [ ] Latest supported iOS version for release
- [ ] Light mode + dark mode
- [ ] Standard contrast + increased contrast
- [ ] Standard motion + Reduce Motion enabled
- [ ] Default text size + largest accessibility text size

## Section Checks (Code Review + QA)

### 1) Semantics and Spoken Output
#### Required
- [ ] Icon-only controls expose meaningful labels
- [ ] Decorative visuals are hidden from accessibility
- [ ] Stateful controls expose value/traits correctly
- [ ] No duplicate spoken output caused by nested accessible elements

#### Common Failure Cases
- [ ] Icon button reads symbol intent instead of action
- [ ] Same title announced twice in one row/card

### 2) Reading Order and Focus
#### Required
- [ ] Spoken order matches task order
- [ ] Sheet/alert focus lands on meaningful content
- [ ] Modal prevents background traversal while active
- [ ] Focus returns to invoking control after modal dismissal

#### Common Failure Cases
- [ ] Sheet opens and VoiceOver navigates background tabs
- [ ] Dismissal returns focus unpredictably

### 3) Dynamic Type and Layout
#### Required
- [ ] No clipped/overlapping text at largest accessibility text size
- [ ] Primary CTA remains visible or reachable via scroll
- [ ] No primary content lost due to fixed heights/widths
- [ ] No dependency on global `minimumScaleFactor` for critical copy

#### Common Failure Cases
- [ ] CTA truncated at AX sizes
- [ ] Dense HStack controls overlap when text scales

### 4) Touch Targets and Input
#### Required
- [ ] All critical controls meet `44x44` pt minimum
- [ ] Swipe-only actions have explicit accessible alternative
- [ ] Dense control clusters avoid accidental taps

#### Common Failure Cases
- [ ] Toolbar icon appears tappable but has tiny hit area
- [ ] Critical action exists only in swipe gesture

### 5) Contrast, Theme, and Non-Color Differentiation
#### Required
- [ ] Text contrast thresholds pass in light mode
- [ ] Text contrast thresholds pass in dark mode
- [ ] Critical non-text indicators are distinguishable
- [ ] Status/error/success states are clear without color

#### Common Failure Cases
- [ ] Red/green status only with no icon/text backup
- [ ] Dark mode card/label contrast too low for readability

### 6) Motion and State Change Communication
#### Required
- [ ] Reduce Motion removes/simplifies non-essential motion
- [ ] Critical state changes remain understandable without movement
- [ ] Important async completion/error updates are announced

#### Common Failure Cases
- [ ] Completion indicated only by animation
- [ ] Error shown visually with no spoken announcement

### 7) Component Regression Sweep
#### Required
- [ ] Buttons and icon-only buttons pass label/size rules
- [ ] Cards and rows avoid duplicate/conflicting semantics
- [ ] Banners and toasts announce critical messages
- [ ] Toggles/pickers expose state correctly
- [ ] Progress indicators expose value or context
- [ ] Empty states provide clear recovery action
- [ ] Sheets/alerts pass focus and dismissal checks
- [ ] Tab/navigation elements expose stable names and selected state

## Media Accessibility (If Applicable)
### Required
- [ ] Captions available for spoken media in task flows
- [ ] Audio descriptions available when visual-only meaning is task-critical

### Common Failure Cases
- [ ] Claimed caption support with missing caption tracks
- [ ] Claimed audio-description support with unavailable descriptive content

## App Store Accessibility Nutrition Label Readiness (9 Labels)
Mark `Ready` only when all common tasks pass for that label.

- [ ] VoiceOver Ready
- [ ] Voice Control Ready
- [ ] Larger Text Ready
- [ ] Dark Interface Ready
- [ ] Differentiate Without Color Ready
- [ ] Sufficient Contrast Ready
- [ ] Reduced Motion Ready
- [ ] Captions Ready (or N/A)
- [ ] Audio Descriptions Ready (or N/A)

Blocking rule:
- [ ] No label is marked Ready if any in-scope common task fails for that label

## Definition of Done (Screen Accessibility Pass)
A screen passes only when all are true:
- [ ] All Project Accessibility Baseline required checks pass
- [ ] No open P0/P1 findings
- [ ] Required section checks pass
- [ ] Media checks pass or are valid N/A
- [ ] Nutrition label impact reviewed and recorded
- [ ] Evidence attached to PR

## Required Evidence for PR
- [ ] Video/screenshot evidence at largest accessibility text size
- [ ] Video/screenshot evidence in dark mode
- [ ] VoiceOver and Voice Control task-run notes
- [ ] List of inferred labels validated and marked `[VERIFY]`
- [ ] Temporary exceptions with owner and due date

## Do Not Do This (Anti-Patterns)
- [ ] Do not mark Ready based on simulator-only confidence
- [ ] Do not mark VoiceOver Ready if one critical task is blocked
- [ ] Do not treat visual parity as accessibility pass
- [ ] Do not defer baseline failures to future cleanup tickets
