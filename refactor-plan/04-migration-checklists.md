# 04 Migration Checklists

This document provides operational, phase-by-phase checklists for executing the LockedIn architectural migration. Each phase includes explicit pre-checks, implementation steps, validation requirements, and stop conditions. 

---

## Phase 0: Baseline & Safety Net

### Pre-checks
- [ ] Ensure the repo is on a clean branch off `main`.
- [ ] Verify `docs/refactor-audit/` is read and understood.

### Implementation
- [ ] Remove `AppClock`, `DevRuntimeState`, and simulation files from the production app target in `.pbxproj`.
- [ ] Remove dead file references from `.pbxproj` (e.g., `IdentityWarningViewModel.swift`).
- [ ] Create/configure the `LockedInTests` target.
- [ ] Write a test asserting `CommitmentSystemStore.recordCompletionDetailed` mutates state exactly as it does currently for a "NORMAL" session.
- [ ] Write a test asserting `PlanStore.reconcileAfterCompletion` processes a queue exactly as it does currently.

### Validation
- [ ] Run `Cmd+U`. The new behavior-lock tests must pass.
- [ ] Launch the app in the simulator and ensure the UI loads normally.

### Completion
- [ ] PR created for Phase 0. No UI or logic was changed.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: The test target cannot be configured or fails to host the SwiftUI environment objects. Do not proceed to Phase 1 until tests can run against the legacy stores.

---

## Phase 1: Structural Scaffolding & Mechanical Moves

### Pre-checks
- [ ] Phase 0 merged.
- [ ] Announce a brief "code freeze" to the team to prevent merge conflicts during folder renaming.

### Implementation
- [ ] Create root folders: `App/`, `Shared/Domain/`, `Shared/Data/`, `Shared/Services/`, `Shared/UI/`, `Features/`.
- [ ] Move `Theme`, colors, and standard buttons to `Shared/UI/`.
- [ ] Move `DateRules` and basic enums to `Shared/Domain/`.
- [ ] Move `Locked_INApp.swift` to `App/`.
- [ ] Run a project-wide find-and-replace to fix broken `import` statements if necessary.

### Validation
- [ ] Build the app (`Cmd+B`). It must compile with zero new warnings.
- [ ] Visually inspect the Project Navigator in Xcode; ensure no files are red/missing.

### Completion
- [ ] Ensure no View `body` or ViewModel logic was altered.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: Xcode project file (`.pbxproj`) becomes corrupted or unmergeable. Discard changes and re-attempt the physical moves using Xcode's native navigator.

---

## Phase 2: Domain Logic Extraction

### Pre-checks
- [ ] Identify the exact lines in `CockpitViewModel` and `DailyCheckInViewModel` that calculate reliability scores.
- [ ] Identify the weekly allowance math in `PlanStore` and `CockpitViewModel`.

### Implementation
- [ ] Create `Shared/Domain/ReliabilityCalculator.swift` (pure functions only).
- [ ] Create `Shared/Domain/WeeklyAllowanceCalculator.swift` (pure functions only).
- [ ] Write exhaustive unit tests for these calculators.
- [ ] Replace the inline math in `CockpitViewModel` and `DailyCheckInViewModel` with calls to the new calculators.

### Validation
- [ ] All unit tests pass.
- [ ] Run app in simulator: ensure Cockpit and Check-in screens display the exact same scores.

### Completion
- [ ] Confirm no global stores or UI navigation flows were altered.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: The new pure functions return different results than the legacy code for edge cases (e.g., timezone boundaries). Fix the pure function to match legacy behavior *exactly* before merging.

---

## Phase 3: Service Wrapper / Data Layer Scaffolding

### Pre-checks
- [ ] Confirm `CommitmentSystemStore` and `PlanStore` are still active `@EnvironmentObject` singletons in the app root.

### Implementation
- [ ] Create protocol `Shared/Domain/CommitmentActionService`.
- [ ] Create class `Shared/Data/LegacyCommitmentWrapper` conforming to the protocol.
- [ ] Inject a reference to the global `CommitmentSystemStore` into the wrapper.
- [ ] Implement the protocol methods by routing them synchronously to the legacy store on the `@MainActor`.
- [ ] Repeat the wrapper pattern for `PlanService` / `LegacyPlanWrapper`.

### Validation
- [ ] Build succeeds.
- [ ] Verify that absolutely no Feature UI is actually using these wrappers yet.

### Completion
- [ ] PR created and merged. 

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: The wrapper attempts to serialize or write its own JSON. Wrappers *must only* forward calls to the legacy stores at this stage.

---

## Phase 4: Feature Migration - Cockpit

### Pre-checks
- [ ] Phase 3 wrappers are merged and available.

### Implementation
- [ ] Create/Update `Features/Cockpit/Presentation/CockpitViewModel`.
- [ ] Inject `CommitmentActionService` into the ViewModel via its `init`.
- [ ] Move the `.onTapGesture` orchestration logic out of `CockpitView` and into the ViewModel's intent functions.
- [ ] Replace `Task.sleep` toast delays in Cockpit with the `Shared/UI` alert presenter.

### Validation
- [ ] Build succeeds.
- [ ] Manual QA: Tap to log a completion in the Cockpit. Verify the standard success toast appears.
- [ ] Manual QA: Switch to the Plan tab immediately. Verify the completion triggered the legacy `PlanStore` sync correctly (proving the Phase 3 wrapper works).

### Completion
- [ ] Confirm `CockpitView` no longer contains direct `@EnvironmentObject` mutations.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: Logging a completion causes UI flicker or desync in other tabs. This indicates the wrapper is introducing asynchronous delays. Force the wrapper to be strictly synchronous on the MainActor.

---

## Phase 5: Feature Migration - DailyCheckIn

### Pre-checks
- [ ] Phase 4 successful; wrapper pattern is proven.

### Implementation
- [ ] Update `Features/DailyCheckIn/Presentation/DailyCheckInViewModel`.
- [ ] Inject the same `CommitmentActionService` into this ViewModel.
- [ ] Replace the legacy `CommitmentSystemStore` direct calls with the Service wrapper.
- [ ] Standardize the `.onAppear` toast/warning emissions to match the Cockpit pattern.

### Validation
- [ ] Manual QA: Trigger a Daily Check-in prompt. Resolve it. 
- [ ] Verify the daily check-in prompt does *not* appear if Recovery mode is active.

### Completion
- [ ] Confirm `DailyCheckInFlowView` contains no generic business logic or `.onAppear` delayed routing.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: The app shell routing gets stuck or loops the daily check-in popup constantly. 

---

## Phase 6: Mechanical Plan Split

### Pre-checks
- [ ] Announce code freeze for `Features/Plan/UI`.

### Implementation
- [ ] Extract `PlanHeaderView` out of `PlanScreen.swift`.
- [ ] Extract `PlanQueueView` out of `PlanScreen.swift`.
- [ ] Extract `PlanEditFormView` out of `PlanScreen.swift`.
- [ ] Pass the existing legacy `@EnvironmentObject` and `@State` bindings down to these new views precisely as they were organically scoped.

### Validation
- [ ] Build succeeds.
- [ ] Manual QA: Drag and drop a plan allocation. Ensure it works smoothly.
- [ ] Manual QA: Open the plan edit form and close it.

### Completion
- [ ] Confirm `PlanScreen.swift` is under 300 LOC.
- [ ] Confirm zero state bindings or domain logic behaviors were changed.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: Any view state is lost during sub-view presentation (e.g., sheets dismiss instantly). Revert the extract and ensure `@State` lifetimes are pinned to the correct parent view.

---

## Phase 7: Feature Migration - Plan & Recovery Semantic Refactor

### Pre-checks
- [ ] Phase 6 mechanical split is merged.

### Implementation
- [ ] Create `Features/Plan/Presentation/PlanViewModel` and `PlanCoordinator`.
- [ ] Move sheet presentation logic (`.sheet(item:)`) into the Coordinator/ViewModel.
- [ ] Inject `PlanService` into the new ViewModels.
- [ ] Refactor `RecoveryModeViewModel` to use the injected Service Wrappers instead of the global singletons.

### Validation
- [ ] Trigger Recovery mode. Pause allocations.
- [ ] Return to Plan view. Verify the plan allocations appear as "paused" via the legacy store sync.
- [ ] Validate Apple Calendar sync interactions still trigger properly.

### Completion
- [ ] All Plan and Recovery UI files observe local ViewModels, not `@EnvironmentObject`.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop if: Apple Calendar visual events disappear from the UI.

---

## Phase 8: Global Store Deprecation and Persistence Finalization

### Pre-checks
- [ ] Search the entire codebase for `@EnvironmentObject var commitmentStore`. It must return 0 hits in UI views.
- [ ] Search the entire codebase for `@EnvironmentObject var planStore`. It must return 0 hits in UI views.

### Implementation
- [ ] Create `Shared/Data/CommitmentDataRepository` managing actual JSON read/writes asynchronously.
- [ ] Create `Shared/Data/PlanDataRepository` managing actual JSON read/writes.
- [ ] Hook these new native repositories into the `Shared/Domain` Service bindings, bypassing the legacy singletons entirely.
- [ ] Delete `CommitmentSystemStore.swift`.
- [ ] Delete `PlanStore.swift`.
- [ ] Delete the destructive one-time launch reset flags in `Locked_INApp.swift`.

### Validation
- [ ] Install this build *over* a legacy build on a physical device or simulator.
- [ ] **Critical Check:** Ensure all legacy allocations and protocols load perfectly. Nothing is wiped.
- [ ] Force-quit the app immediately after logging a completion. Relaunch and verify it saved successfully.

### Completion
- [ ] The codebase contains no legacy god-stores.
- [ ] Performance and scroll hitches are eliminated during saves.
- [ ] PR created and merged.

### 🛑 Escalation Triggers / Stop Conditions
- Stop instantly if: The app launches into an empty state. The new pure Repositories must correctly decode the legacy JSON schemas. Do not merge Phase 8 if data migration fails.
