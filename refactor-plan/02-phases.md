This document outlines the strictly ordered, incremental phases required to transition LockedIn from its current state (heavy global stores, UI-orchestrated rules) to the approved target architecture defined in `01-target-architecture.md`.

The strategy prioritizes safety, behavior preservation, and mechanical moves before semantic structural changes. It heavily leverages the "Legacy Store Coexistence Pattern" to keep the app functional while individual features are modernized.

---

## Phase 0: Baseline and Safety Net

**Objective:** Clean up immediate production risks and document existing behavior with explicit behavioral safety nets before moving any structural code.
**Why this phase comes first:** We cannot safely refactor the orchestration of critical flows if we don't have a reliable way to verify that we haven't broken the app's core mathematical and persistence rules.

- **Scope:** Build targets, unused files, and high-level behavioral unit tests against current stores.
- **Likely files/modules affected:** `.pbxproj`, `LockedInTests`, `docs/`, `CommitmentSystemStore`, `PlanStore`.
- **Prerequisites:** Pass A and Pass B audits complete (Done).
- **Exact tasks:**
  1. Remove any dead or strictly simulation-only files from the production app target (e.g., `AppClock`, `DevRuntimeState` inclusions if they leak into prod).
  2. Fix `.pbxproj` missing path references (e.g., missing `IdentityWarningViewModel.swift`).
  3. Create a `LockedInTests` target if it doesn't actually exist/compile.
  4. Write black-box characterization tests for `CommitmentSystemStore.recordCompletionDetailed` and `PlanStore.reconcileAfterCompletion` asserting exact current side-effects for a given input state.
- **What must NOT change:** 
  - No code is moved. No UI is changed. No app logic is altered.
- **Verification steps:** 
  - CI/CD or local `Cmd+u` passes. 
  - App launches and behaves identically.
- **Rollback strategy:** Revert Git commit. No structural changes made.
- **Definition of done:** The test suite passes with at least 5 core scenarios covering the completion and recovery logic chains.

---

## Phase 1: Structural Scaffolding and Mechanical Moves

**Objective:** Create the physical folder structure for the target architecture and mechanically hoist safe, stateless shared code into it.
**Why this phase comes next:** Teams need the destination folders physically present to start migrating code. Extracting basic UI primitives and data types mechanically reduces noise before any semantic refactoring begins.

- **Scope:** Directory reorganization under `Shared/UI` and `Shared/Domain`, moving theme and pure utility types.
- **Likely files/modules affected:** Theme colors, typography, DateRules, simple `enums`.
- **Prerequisites:** Phase 0 complete and tests passing.
- **Exact tasks:**
  1. Create the `App`, `Shared/Domain`, `Shared/Data`, `Shared/Services`, `Shared/UI`, and `Features` directory tree.
  2. Move pure domain types (e.g., `DateRules`, `CommitmentProtocol`) into `Shared/Domain`.
  3. Move design system components (colors, fonts, standard buttons) into `Shared/UI`.
  4. Move app shell files (`Locked_INApp.swift`, app router) into `App/` and `Features/AppShell/`.
  5. Fix all `import` or path references broken by the move.
- **What must NOT change:** 
  - No View models are created or destroyed. No View `body` behavior logic is altered. 
- **Verification steps:** Full build and run. Execute manual click-throughs to ensure assets resolve correctly.
- **Rollback strategy:** Revert mechanical file moves via Git. 
- **Definition of done:** The new repository directory tree matches `01-target-architecture.md`, compiling without warnings.

---

## Phase 2: Domain Logic Extraction

**Objective:** Extract duplicated or UI-bound business logic into pure, stateless domain functions. 
**Why this phase comes next:** We must deduplicate the "brain" of the app (like reliability scoring and weekly cap logic) before rewriting ViewModels, giving future feature migrations a single well-tested source of truth to call.

- **Scope:** Extracting mathematical formulas and pure logic from ViewModels and Stores.
- **Likely files/modules affected:** `CockpitViewModel`, `DailyCheckInViewModel`, `PlanStore`, `Shared/Domain`.
- **Prerequisites:** Phase 1 structural layout is ready.
- **Exact tasks:**
  1. Create pure Swift business rule structs in `Shared/Domain` (e.g., `ReliabilityCalculator`, `WeeklyAllowanceCalculator`).
  2. Write unit tests for these newly extracted pure functions.
  3. Update `CockpitViewModel` and `DailyCheckInViewModel` to call these new shared calculators instead of their internal duplicated formulas.
- **What must NOT change:** 
  - The UI layers still observe the same ViewModels. Global stores and routing remain untouched.
- **Verification steps:** Unit tests pass. Manually verify the reliability scores match on Cockpit and Check-in screens for the same user state.
- **Rollback strategy:** Revert to legacy duplicated ViewModel formulas.
- **Definition of done:** `CockpitViewModel` and `DailyCheckInViewModel` share the exact same `Shared/Domain` calculators; tests exist for all extracted formulas.

---

## Phase 3: Service Wrapper / Data Layer Scaffolding

**Objective:** Introduce clean interfaces (Protocols/Repositories) that securely wrap the legacy global stores, establishing the "Coexistence Pattern."
**Why this phase comes next:** We need clean `Data` dependencies ready for the upcoming feature migrations. Wrapping the legacy stores now means migrated features can use the final architectural patterns (`ViewModel -> Protocol`) while the underlying implementation transparently syncs with the legacy global `@EnvironmentObject`s until `Phase 8`.

- **Scope:** Creating `Shared/Data` protocols and wrapper implementations.
- **Likely files/modules affected:** New wrapper files in `Shared/Data/`.
- **Prerequisites:** Phase 2 complete.
- **Exact tasks:**
  1. Define narrow use-case protocols (e.g., `CommitmentActionService`) in `Shared/Domain`.
  2. Implement these protocols in `Shared/Data` with a concrete wrapper class that internally holds a reference to the legacy `CommitmentSystemStore` singleton.
  3. Do the same for `PlanService` wrapping `PlanStore`.
- **What must NOT change:** 
  - No UI or ViewModel uses these wrappers yet. They are purely scaffolding. Legacy `EnvironmentObject` stores remain in full production use everywhere.
- **Verification steps:** Build succeeds. 
- **Rollback strategy:** Delete the new wrapper files.
- **Definition of done:** Narrow protocols exist in domain, and concrete wrapper implementations exist in `Data` ready to be injected.

---

## Phase 4: Feature Migration - Cockpit

**Objective:** Migrate the Cockpit feature (presentation logic, state observation, and routing) to the new architecture.
**Why this phase comes next:** Cockpit is the primary entry point for behavior. Migrating it alone validates the service wrappers before touching the rest of the app.

- **Scope:** `Features/Cockpit/UI` and `Features/Cockpit/Presentation`.
- **Likely files/modules affected:** `CockpitView`.
- **Prerequisites:** Phase 3 wrappers are available.
- **Exact tasks:**
  1. Strip all direct `EnvironmentObject` usage and `recordCompletionDetailed` orchestration loops out of `CockpitView`'s `.onTapGesture` blocks.
  2. Implement `Features/Cockpit/Presentation/CockpitViewModel` to orchestrate writes using the injected Phase 3 Service Wrapper.
  3. Replace the local manual `Task.sleep` toast timers with a standardized `Shared/UI` alert presenter model.
- **What must NOT change:** 
  - DailyCheckIn, Plan, and Onboarding are untouched. `CommitmentSystemStore` remains authoritative.
- **Verification steps:** Log a completion in Cockpit. Verify routing and toast UX. Verify that legacy screens (like Plan) instantly reflect the change via the wrapper syncing the legacy store.
- **Rollback strategy:** Revert the Cockpit directory.
- **Definition of done:** `CockpitView` contains zero business logic and zero direct store mutations.

---

## Phase 5: Feature Migration - DailyCheckIn

**Objective:** Migrate the DailyCheckIn feature to the new architecture to match Cockpit.
**Why this phase comes next:** DailyCheckIn shares heavy conceptual overlap with Cockpit. Migrating it now fully standardizes how "completions" enter the system.

- **Scope:** `Features/DailyCheckIn/UI` and `Features/DailyCheckIn/Presentation`.
- **Likely files/modules affected:** `DailyCheckInFlowView`, `DailyCheckInViewModel`.
- **Prerequisites:** Phase 4 completed.
- **Exact tasks:**
  1. Re-wire `DailyCheckInViewModel` to use the injected Phase 3 Service Wrappers instead of touching `CommitmentSystemStore` directly.
  2. Standardize its toast and navigation intent emission to match the pattern established in Phase 4.
- **What must NOT change:** 
  - The core "regulator" logic dictating when a check-in is required must not change behavior.
- **Verification steps:** Resolve a pending check-in. Verify standard success overlays instead of custom timers. Wait for Plan sync.
- **Rollback strategy:** Revert the DailyCheckIn directory.
- **Definition of done:** Both primary completion surfaces (Cockpit and CheckIn) use identical standardized service layer routes to mutate data.

---

## Phase 7: Feature Migration - Plan Routing & Coordinator

**Objective:** Extract all navigation intent consumption logic out of `PlanScreen` and into a dedicated `PlanCoordinator`.
**Why this phase comes next:** Before migrating `PlanViewModel`'s heavy data logic to Service Wrappers, we must isolate the UI's reaction to global intents (like deep links to edit a protocol). Moving intent consumption out of the SwiftUI `.onChange` graph stabilizing the UI lifecycle first.

- **Scope:** `Features/Plan/Presentation` and `Features/Plan/UI`.
- **Likely files/modules affected:** `PlanScreen.swift`, new `PlanCoordinator.swift`.
- **Prerequisites:** Phase 6 complete.
- **Exact tasks:**
  1. Create `Features/Plan/Presentation/PlanCoordinator` to observe `AppRouter`.
  2. Move the `AppRouter` `.onChange` and intent consumption (e.g., focus protocol, open editor) out of `PlanScreen`.
  3. Change `PlanScreen` to observe the new local `PlanCoordinator` for its sheet presentation and focus state.
- **What must NOT change:** 
  - `PlanViewModel` still uses legacy global stores. `RecoveryMode` is untouched.
- **Verification steps:** Trigger a check-in or toast that routes to `Plan` and opens the editor. Ensure the sheet still presents exactly as before.
- **Rollback strategy:** Revert `PlanCoordinator` and restore `.onChange` bindings in `PlanScreen`.
- **Definition of done:** `PlanScreen` does not directly observe `AppRouter` intents.

---

## Phase 8: Feature Migration - Recovery Services 

**Objective:** Migrate `RecoveryModeViewModel` to use the Phase 3 Service Wrappers instead of the legacy global stores.
**Why this phase comes next:** The Recovery domain is smaller and more isolated than the Plan domain. Migrating it first forces us to safely expand the Service Wrappers' capabilities (like pausing allocations) before tackling the massive `PlanViewModel`.

- **Scope:** `Features/Recovery` and `Shared/Data` wrappers.
- **Likely files/modules affected:** `RecoveryModeViewModel.swift`, Service Wrappers.
- **Prerequisites:** Phase 7 complete.
- **Exact tasks:**
  1. Inject `CommitmentActionService` and `PlanService` into `RecoveryModeViewModel`.
  2. Implement any missing wrapper functions required by Recovery (e.g., `recoveryEntryContext()`, `pauseAllocations()`).
  3. Ensure the wrappers forward synchronously to the legacy stores.
  4. Remove all direct `PlanStore` and `CommitmentSystemStore` references from `RecoveryModeViewModel`.
- **What must NOT change:** 
  - `PlanViewModel` and `PlanScreen` are untouched.
- **Verification steps:** Trigger recovery mode, pause an allocation, and ensure the UI reflects it. 
- **Rollback strategy:** Restore legacy store references in `RecoveryModeViewModel`.
- **Definition of done:** `RecoveryModeViewModel` interacts solely with Service Wrappers.

---

## Phase 9: Feature Migration - Plan Services 

**Objective:** Migrate the heavy business logic in `PlanViewModel` to use the Phase 3 Service Wrappers.
**Why this phase comes next:** This is the largest and riskiest migration. By isolating it into its own phase, we ensure the Service Wrappers and the UI routing are completely stable before touching the complex Plan data mapping logic.

- **Scope:** `Features/Plan/Presentation` and `Shared/Data` wrappers.
- **Likely files/modules affected:** `PlanViewModel.swift`, Service Wrappers.
- **Prerequisites:** Phase 8 complete.
- **Exact tasks:**
  1. Remove the legacy `.bind(planStore:commitmentStore:)` method and weak global properties from `PlanViewModel`.
  2. Inject `CommitmentActionService` and `PlanService` into `PlanViewModel` at initialization.
  3. Expand the Service Wrappers to handle the complex reads and writes `PlanViewModel` requires (e.g., fetching snapshots, editing protocols).
  4. Verify all wrapper expansions strictly sync with the legacy stores on the `@MainActor`.
- **What must NOT change:** 
  - Data saved to disk. Calendar Sync logic.
- **Verification steps:** Perform heavy edits, drags, and queue modifications in the Plan tab. Verify Apple Calendar sync still triggers accurately.
- **Rollback strategy:** Revert `PlanViewModel` and any newly added Service Wrapper methods.
- **Definition of done:** `PlanViewModel` has zero references to `PlanStore` or `CommitmentSystemStore`.

---

## Phase 10: Global Store Deprecation and Persistence Finalization

**Objective:** Delete the legacy global stores (`PlanStore` and `CommitmentSystemStore`) and finalize the data layer.
**Why this phase comes last:** Only after every UI feature (Phases 4, 5, 8, 9) has been migrated to use Service Wrappers can we safely remove the underlying global EnvironmentObjects that powered them. 

- **Scope:** Deprecation of the legacy global stores, final JSON persistence wiring.
- **Likely files/modules affected:** `App/Locked_INApp.swift`, `CommitmentSystemStore`, `PlanStore`, `Shared/Data/JSONRepositories`.
- **Prerequisites:** All Feature UI (Cockpit, Plan, Check-In, Recovery, Onboarding) are fully isolated from view-level store mutations.
- **Exact tasks:**
  1. Refactor the Service wrappers to directly perform the JSON read/write logic using pure Repositories `Shared/Data/CommitmentDataRepository` and `Shared/Data/PlanDataRepository`.
  2. Implement background/async write strategies to replace the legacy blocking `Data(contentsOf:)` calls on the MainActor.
  3. **Delete `CommitmentSystemStore.swift` and `PlanStore.swift`.**
  4. Remove the destructive startup flag logic from `Locked_INApp.swift` to prevent accidental production resets.
- **What must NOT change:** 
  - The actual `.json` formats saved to disk. User data must effortlessly bridge over to the new repository pattern.
- **Verification steps:** Build and deploy over an existing app install. Ensure existing data reads successfully, mutations persist through force-quits, and there is no UI jank during large queue writes.
- **Rollback strategy:** Restore the singletons from source control if data migration fails.
- **Definition of done:** `@EnvironmentObject var planStore` and `@EnvironmentObject var commitmentStore` no longer exist anywhere in the codebase.
