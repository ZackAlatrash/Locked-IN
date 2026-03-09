# 03 Risk Register

This document tracks the specific architectural, behavioral, and organizational risks associated with the LockedIn phased refactoring. Risks are mapped to the constraints defined in `01-target-architecture.md` and the steps in `02-phases.md`.

## RR-01: Persistence/Data Loss
- **Risk Title:** Silent data loss during JSON repository migration.
- **Description:** Phase 10 deprecates the legacy stores and wires up abstract Repositories. If models decode differently or fail to save asynchronously, users could lose plan allocations or protocol history.
- **Likely Cause:** Differences between legacy `Data(contentsOf:)` synchronous reads and new async Data/JSON mappings, or unexpected background task cancellation during the new async write strategy.
- **Impact:** Critical (user loses progress/data).
- **Likelihood:** Medium.
- **Detection Signal:** Repository fetch operations fail and return empty lists or throw decoding errors during startup; user reports missing data on app restart.
- **Mitigation Strategy:** Implement strict unit tests for the new `Shared/Data` repositories against a static mock JSON matching a known legacy production state.
- **Contingency / Rollback Response:** Temporarily restore the legacy singletons in `Locked_INApp.swift` to read data, pause rollout of Phase 10.
- **Affected Phases:** Phase 10.

## RR-02: Behavior Drift (Domain Rules)
- **Risk Title:** Math/Scoring formula divergence during pure function extraction.
- **Description:** Moving reliability scores and weekly allowance math from ViewModels and Stores into `Shared/Domain` (Phase 2) might accidentally alter edge-case behavior.
- **Likely Cause:** Overlooking a hidden state variable in the old ViewModels (e.g., timezone offsets) when creating the pure `calculator(state:)` functions.
- **Impact:** High (users see incorrect remaining sessions or locked states).
- **Likelihood:** Low-Medium.
- **Detection Signal:** Unit tests added in Phase 2 fail, or Cockpit and Check-in screens show mismatched numbers post-Phase 2.
- **Mitigation Strategy:** Write characterization tests against the legacy formulas *before* extracting them to `Shared/Domain`, ensuring outputs match perfectly for 10+ varied input combinations.
- **Contingency / Rollback Response:** Re-embed the legacy formula temporarily in the affected ViewModel workspace while keeping the new shared pure function active on non-critical paths.
- **Affected Phases:** Phase 2.

## RR-03: UI / Navigation Regression
- **Risk Title:** Modal conflicts and dropped intents during UI isolation.
- **Description:** As routing is removed from `.onAppear` blocks and views (Phases 4, 5, 7) and consolidated into Coordinators or shell intents, race conditions could cause popups to overlap or deep-links (like jumping to `PlanEdit`) to drop.
- **Likely Cause:** View transition delays or differences in when SwiftUI evaluates `.sheet` vs `.navigationDestination` bindings in the new architecture.
- **Impact:** High (user gets stuck or cannot close a sheet).
- **Likelihood:** Medium-High.
- **Detection Signal:** AppShell daily-checkin popup fails to present, or Cockpit-to-Plan jump silently fails.
- **Mitigation Strategy:** Do not alter the `MainAppView` global gating logic during individual feature phases. Only change local feature navigation. 
- **Contingency / Rollback Response:** Re-attach the legacy `.isPresented` state manually via local `@State` flags until the Coordinator lifecycle is debugged.
- **Affected Phases:** Phases 4, 5, 7.

## RR-04: Legacy Store Coexistence
- **Risk Title:** Race conditions between Coexistence Wrappers and legacy Global Stores.
- **Description:** In Phases 3-9, migrated features use `Shared/Data` wrappers that internally mutate the legacy stores. If a migrated feature reads from the legacy store faster/slower than an unmigrated feature, UI inconsistencies will appear.
- **Likely Cause:** Adding `Task` or `DispatchQueue.main.async` hops inside the wrapper protocols that artificially delay the synchronous mutations expected by the legacy views.
- **Impact:** Medium (temporary UI flicker or stale reads on unmigrated tabs).
- **Likelihood:** High.
- **Detection Signal:** "Plan" tab shows old active protocol state even when "Cockpit" tab has just recorded it as complete.
- **Mitigation Strategy:** Wrappers must execute their internal legacy store mutations synchronously on the `@MainActor` during coexistence phases. Do not introduce background async behavior to the wrappers until Phase 10.
- **Contingency / Rollback Response:** Strip the wrapper interface bounds and revert the specific migrated feature's ViewModel to talk to `@EnvironmentObject` directly again.
- **Affected Phases:** Phases 3, 4, 5, 8, 9.

## RR-05: Cross-Feature Sync (Recovery vs Daily)
- **Risk Title:** Recovery pause logic desyncs from daily check-in prompt logic.
- **Description:** The legacy shell relies on fragile state reads to suppress check-in when Recovery is active. Refactoring either system independently might bypass the suppression.
- **Likely Cause:** Extracting `RecoveryModeViewModel` (Phase 8) or `DailyCheckInViewModel` (Phase 5) changes the timing of when recovery flags hit `@AppStorage` or the global singletons.
- **Impact:** High (user is forced to check-in while physically recovered, corrupting data).
- **Likelihood:** Medium.
- **Detection Signal:** Manual QA observes Daily Check-In popup triggering while Recovery mode is actively pausing the app.
- **Mitigation Strategy:** Write explicit black-box checks (Phase 0) for this exact overlapping state.
- **Contingency / Rollback Response:** Revert Phase 5 or Phase 8 depending on which introduced the race condition.
- **Affected Phases:** Phase 5, Phase 8.

## RR-06: Performance Blind Spots
- **Risk Title:** Excessive view invalidations post-migration.
- **Description:** Moving from giant `@EnvironmentObject` observation to local ViewModels could accidentally cause entire tab re-renders if StateObject lifecycles are configured poorly at the `AppShell` level.
- **Likely Cause:** Accidentally initializing ViewModels inside `body` variables without `@StateObject`, or publishing changes on `ObservableObject` properties too broadly.
- **Impact:** Medium (UI jank, battery drain).
- **Likelihood:** Medium.
- **Detection Signal:** SwiftUI `_printChanges()` logs continuous hits; app scrolling stutters on the plan queue view.
- **Mitigation Strategy:** Strict adherence to `@State` and `@StateObject` (or `@Observable` in iOS 17+) boundaries. Phase 6 mechanical split must preserve native bindings precisely.
- **Contingency / Rollback Response:** Move the injected ViewModel up one layer to the parent container to stabilize its memory footprint.
- **Affected Phases:** Phases 4, 5, 6, 7, 9.

## RR-07: Test Coverage Deficiencies
- **Risk Title:** Phase 0 tests don't actually cover critical boundary cases.
- **Description:** Because the app has no existing test suite, the tests created in Phase 0 might accidentally mock too much or test the wrong layer, providing a false sense of security.
- **Likely Cause:** Testing only "happy path" completions, missing timezone boundaries, missing missing-storage-file paths, or missing recovery intersections.
- **Impact:** High (allows regressions to slip through to Phase 8 unseen).
- **Likelihood:** Medium.
- **Detection Signal:** Phase 2 logic extraction mathematically changes behavior, but Phase 0 tests still pass.
- **Mitigation Strategy:** Enforce "mutation tests": deliberately change a legacy formula factor to see if the Phase 0 test actually fails.
- **Contingency / Rollback Response:** Halt Phase 2 and spend more time expanding Phase 0 coverage before proceeding.
- **Affected Phases:** Phase 0, Phase 2.

## RR-08: Architecture / Over-Abstraction Drift
- **Risk Title:** Introduction of generic bloat during Domain abstraction.
- **Description:** Developers might create overly generic "Clean Architecture" interfaces (e.g., `AnyService<T>`, `GenericUseCaseManager`) that make the SwiftUI codebase harder to read and trace than the legacy god-objects.
- **Likely Cause:** Treating "Strict Layering" as an instruction to obscure concrete implementations rather than just isolating responsibilities.
- **Impact:** Medium (slows development velocity, lowers developer satisfaction).
- **Likelihood:** High.
- **Detection Signal:** Feature PRs contain 5+ protocol definitions for a single UI button tap.
- **Mitigation Strategy:** Review PRs against Section 9 of `01-target-architecture.md` ("Anti-Patterns to Avoid"). Protocols should *only* be used for the Data layer boundary or if multiple implementations exist.
- **Contingency / Rollback Response:** Reject PRs that over-abstract. Enforce concrete Structs for domain logic in Phase 2.
- **Affected Phases:** Phase 2, Phase 3.

## RR-09: Merge Conflicts (Project Organization)
- **Risk Title:** Unresolvable git histories during mechanical file shifts.
- **Description:** Renaming folders to `Shared/` and `Features/UI/` (Phase 1) and physically dissecting `PlanScreen` (Phase 6) will collide violently with any concurrent product feature work.
- **Likely Cause:** Merging long-running feature branches during Phase 1 or Phase 6.
- **Impact:** High (lost work, broken build graphs).
- **Likelihood:** Very High.
- **Detection Signal:** Xcode `.pbxproj` collisions or "file not found" compiler errors immediately after merging `main`.
- **Mitigation Strategy:** Impose brief, explicitly announced codebase freezes during Phase 1 and Phase 6.
- **Contingency / Rollback Response:** Discard the merge commit, pull `main`, and mechanically re-apply the feature branch on top of the new folder structure.
- **Affected Phases:** Phase 1, Phase 6.
