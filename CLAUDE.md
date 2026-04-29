# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Run

This is a pure Xcode project — no SPM packages, no CocoaPods, no external dependencies.

```bash
# Build (debug)
xcodebuild -project "LockedIn.xcodeproj" -scheme LockedIn -configuration Debug build

# Build for simulator
xcodebuild -project "LockedIn.xcodeproj" -scheme LockedIn -destination 'platform=iOS Simulator,name=iPhone 16' build
```

There are **no test targets**. The architecture is designed for testability (protocol repos, pure engines, in-memory implementations) but no tests exist yet.

Deployment target: **iOS 26.0**. Always test in an iOS 26 simulator.

---

## Architecture

Three strict layers — never import upward:

```
Domain/          → Pure Swift structs/enums. Zero framework imports. All business logic.
Application/     → @MainActor stores. Bridge between domain and SwiftUI.
Features/        → SwiftUI views + ViewModels. One folder per feature.
Core/            → Repository protocols + JSON file implementations + AI service boundary.
CoreUI/          → Shared UI components, Theme namespace, Haptics, MotionRuntime.
```

**Domain engines** are pure structs that take `inout CommitmentSystem` and mutate it. No `@Published`, no SwiftUI.

**Stores** (`CommitmentSystemStore`, `PlanStore`) are `@MainActor final class: ObservableObject`. The mutation pattern is always:
```swift
var updated = system
// call engine methods on &updated
system = updated
persistSystem()
```

**Policy before action:** `CommitmentPolicyEngine` is the single gatekeeper for what is allowed. Always check `.allow()` / `.deny(PolicyReason)` before mutating state. `PolicyReason` carries user-facing `PolicyCopy` (title, message, hint).

**Feature module layout:**
```
Features/FeatureName/
  Views/          ← struct: View
  ViewModels/     ← @MainActor final class: ObservableObject
  Models/         ← feature-local value types
  Components/     ← feature-local reusable views
```

ViewModels use an **action enum pattern** — views call `viewModel.perform(.someAction)`, keeping logic out of view bodies.

---

## Domain Model Relationships

`CommitmentSystem` is the root aggregate. It owns `[NonNegotiable]`, which each carry a `NonNegotiableDefinition` (immutable spec), `NonNegotiableState` (lifecycle), `LockConfiguration` (28-day lock, 14-day windows), `[CompletionRecord]`, and `[Violation]`.

`PlanAllocation` lives separately in `PlanStore` and references protocols by `UUID`. The Plan layer is the only place `PlanAllocation` is persisted or reasoned about.

`WeekID` (ISO year + week number) is the universal week identifier. All date logic must use `DateRules.isoCalendar` (ISO 8601, Monday-start) — never `Calendar.current` for week-based work. Use `AppClock` instead of `Date()` so dev tooling can simulate dates.

---

## Persistence

JSON files in the Documents directory via `JSONFileCommitmentSystemRepository` and `JSONFilePlanAllocationRepository`. Date strategy is `.iso8601` everywhere. Atomic writes only.

Legacy key migration is done in-place inside `Codable init(from:)` using `decodeIfPresent` + fallback values — no migration versioning system exists.

UserDefaults holds: onboarding/walkthrough completion flags, appearance mode, `DailyCheckInPolicy` timing keys, and one-time migration sentinels.

---

## Key Conventions

**Naming:** Domain says "NonNegotiable"; UI says "protocol." Never use "habit" or "task" in UI copy.

**Theme:** All design tokens are in `enum Theme` — `Theme.Colors`, `Theme.Typography`, `Theme.Spacing`, `Theme.CornerRadius`, `Theme.Shadows`, `Theme.Animation`. Never hardcode colors, fonts, or spacing inline. Custom font is Inter Variable, loaded via `Theme.Typography`.

**Simulation files:** Every domain engine has a paired `*Simulation.swift` with factory methods for SwiftUI previews and the DevOptions seeder. Add one when adding a new engine.

**Walkthrough frames:** Spotlight overlays use a `PreferenceKey` pattern (`CockpitWalkthroughFramePreferenceKey`) to bubble `[FrameID: CGRect]` from children to the parent overlay layer. Follow this pattern for any new walkthrough steps.

**Accessibility:** Check `accessibilityReduceMotion` before any animation. Mark unresolved accessibility TODOs with `// [VERIFY]`.

**Concurrency:** Project-wide `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. For auto-dismiss toasts: `Task { @MainActor in try? await Task.sleep(nanoseconds:) }`.

---

## Dev Tooling (built-in)

- **`AppClock`** — inject and use instead of `Date()` so that `DevOptions` can simulate any date.
- **`DevOptionsController`** — seeds five named scenarios: `freshStartMinimal`, `stableWeek`, `overloadedWeek`, `checkInDueTonight`, `usedForAWhile`. Use a seed instead of manually constructing state.
- **`DevRuntimeState`** — force-triggers the check-in popup, overrides reliability score.
- **`InMemoryCommitmentSystemRepository`** — use this in SwiftUI previews instead of the JSON repo.
