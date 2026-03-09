# 01 Target Architecture

## 1. Current-State Summary
The audit of LockedIn reveals an architecture struggling under the weight of shared mutability and scattered responsibilities. The primary structural problems are:
- **Responsibility Collapse:** Global, mutable stores (`CommitmentSystemStore` and `PlanStore`) act as "god objects," mixing domain logic, persistence, and UI state.
- **UI-Layer Orchestration:** Business flows, multi-store mutation chains, and routing intents are often executed directly from SwiftUI Views (e.g., `CockpitView`, `MainAppView`) or inconsistently from ViewModels.
- **Fragmented Navigation:** Screen flow is split between shell-managed global overlays, ad-hoc router intents, and manually managed local sheets, creating cross-feature coupling and flow fragility.
- **Logic Duplication:** Core domain rules (e.g., reliability scoring formulas, daily completion side-effects) and UI patterns (profile sheets, toast timers) are duplicated across feature silos (`Cockpit` vs. `DailyCheckIn`).
- **Synchronous Persistence:** I/O operations block the main thread, and durable state (via `@AppStorage`) is mutated by arbitrary feature screens and startup lifecycle resets.

## 2. Architectural Direction
The refactoring effort will move LockedIn toward a **Strictly Layered Component Architecture** that isolates state, restricts dependency flow, and extracts domain orchestration out of the UI.
- **State Isolation:** Transition away from sprawling `@EnvironmentObject` singletons. Adopt narrow, use-case specific state models for each screen.
- **Centralized Orchestration:** Move navigation and cross-feature routing into a dedicated Coordinator/Flow layer, removing logic from View `.onAppear` blocks.
- **Shared vs. Feature Boundaries:** Truly shared domain behavior (business rules, persistence) and shared primitives (UI components, theme) must be fully abstracted into a `Shared` layer. Features will contain only UI rendering and feature-local application state.
- **Dependency Flow:** Dependencies must flow strictly downwards: **Views → ViewModels/Coordinators → Domain Services/Use Cases → Persistence Repositories**. Upward communication should rely on protocol delegation or reactive publishers.

## 3. Target Structure
The repository will be reorganized to strictly map to architectural responsibilities, prioritizing a flatter `Shared` structure over a nested `Core` layout:

### Recommended Top-Level Repo Structure
```text
LockedIn/
├── App/                # App lifecycle (Locked_INApp), DI container, early startup
├── Shared/             # Code used by more than one feature
│   ├── Domain/         # Shared protocols, entities, and cross-feature business rules
│   ├── Data/           # Persistence, API clients, and repositories (JSON, UserDefaults)
│   ├── Services/       # External integrations (e.g., AppleCalendarService)
│   └── UI/             # (Formerly CoreUI) Design System, standard cards, and modifiers
├── Features/           # Vertical slices containing feature-specific code
│   ├── AppShell/       # Tab management, overlay gating, global navigation
│   ├── Cockpit/
│   ├── Plan/
│   ├── DailyCheckIn/
│   └── Recovery/
└── Resources/          # Assets, Localizable.strings
```

*Note on `Shared/UI` vs `CoreUI`: We will use `Shared/UI` because it clearly communicates that these are simply UI components used by multiple features, avoiding the implication that UI is part of the application's "Core" domain. It keeps all shared code grouped under one mental model (`Shared/`).*

### Recommended Per-Feature Structure
Inside a feature (e.g., `Features/Plan/`), folder names must be unambiguous:
```text
Features/Plan/
├── UI/                 # Pure SwiftUI views (split into small, focused files)
├── Presentation/       # ViewModels managing feature-specific UI state
├── Domain/             # Feature-local pure business logic (rules, calculators)
└── Data/               # (Optional) Feature-local data mapping or specific API requests

# Avoid ambiguous names like `Models/` or `Logic/`. 
# If a model is just for the view locally, it goes in Presentation/.
# If it's a domain struct only used by this feature, it goes in Domain/.
```

## 4. Boundary Rules
- **View Dependencies:** A View may only depend on its specific ViewModel, local `@State`, or `Shared/UI` components. Views must not reference domain Services or Repositories directly.
- **Shared vs Feature Domain:**
  - `Shared/Domain`: Logic and types required by *two or more* features (e.g., core `Protocol` entity, or `calculateReliability` if shared).
  - `Feature/Domain`: Logic only relevant to that feature (e.g., `PlanQueueBuilder` used only by `Plan`).
- **Feature Isolation:** Features (`Cockpit`, `Plan`, etc.) cannot directly import each other’s internal views or ViewModels. Cross-feature transitions must occur through shared routing intents handled by the `AppShell`.
- **Navigation & Coordinators:** Coordinators are **not required everywhere**. Use SwiftUI's native `NavigationStack` and `sheet` for simple, feature-local navigation. Coordinators or explicit Router objects should only be introduced for complex, multi-step flows (like Onboarding) or global cross-feature routing (owned by `AppShell`). Avoid over-engineering simple pushes.
- **Side Effect Isolation:** Domain writes (e.g., saving completion to disk) must happen logically behind a ViewModel or Service boundary, guaranteeing that multiple stores cannot be mutated asynchronously by a View.

## 5. Code Ownership Rules
- **SwiftUI Views (`Features/*/UI/`):** Responsible exclusively for layout, view bindings, animation, and emitting user intents. No data fetching, persisting, or complex calculation.
- **ViewModels (`Features/*/Presentation/`):** Maintain presentation state, format data for views, and invoke Services or Domain operations in response to UI actions. Feature-specific models/DTOs live here.
- **Domain Logic (`Shared/Domain/` or `Features/*/Domain/`):** Pure functions and business rules. Structs living here represent the core business, decoupled from JSON or UI.
- **Data/Repositories (`Shared/Data/`):** Abstract the underlying storage mechanism (`JSONFile*`). They expose asynchronous interfaces and handle serialization. Only shared models live here.
- **Analytics & Settings:** Handled via dedicated abstract services, never through scattered `@AppStorage` bindings in views.

## 6. Standardization Guidance
- **Naming Conventions:** Class/struct names must clearly indicate their layer (`ProtocolListViewModel`, `FetchPlanUseCase`, `JSONCommitmentRepository`). Legacy vague names like `PlanStore` should be deprecated.
- **Mitigating God Objects:** Large screens (e.g., `PlanScreen.swift`) must be physically split. One SwiftUI View file should ideally not exceed 300 LOC. Break forms, headers, and sheets into separate files within the feature `UI` folder.
- **Promotion to Shared:** Code starts feature-local. It is only hoisted to `Shared` or `Shared/UI` when a second feature explicitly requires the exact same behavior or visual element. Do not prematurely abstract.
- **UI Consistency:** Do not use manual `Task.sleep` delays for toast routing. Leverage a shared `Shared/UI` presenter for all transient alerts.

## 7. Stable Behavior Constraints
During the incremental refactor, the following constraints must be aggressively preserved:
- **User-visible flow:** The navigation graph, user journeys, app startup behavior, and visual tab selection must remain identical to the user.
- **Data Persistence Compatibility:** The underlying JSON formats for `commitment_system.json` and `plan_allocations.json` must be flawlessly preserved. No silent data loss is acceptable.
- **Core Constraints:** Apple Calendar read behaviors, daily check-in prompt timings, and the recovery pause logic must remain intact.
- **Event Intent:** Any refactoring of UI elements must retain identical side effects for the core domain operations (e.g., logging a completion).

## 8. Migration Suitability
This architecture is designed explicitly for **incremental migration**, avoiding a total rewrite. 
- **Legacy Store Coexistence Pattern:** The giant `CommitmentSystemStore` and `PlanStore` will initially remain exactly where they are as `@EnvironmentObject` singletons. 
  - As we migrate a feature (e.g., DailyCheckIn), we will build the new `ViewModel` and `Data` layer. The new ViewModel will read from/write to the new layer, which *internally* syncs with or wraps the legacy stores until all features are migrated. 
  - This allows migrated features to use the clean architecture while untouched features still run on the legacy global stores without breaking.
- **Top-Down & Bottom-Up Friendly:** We can incrementally extract raw business logic (like the reliability scores) into stateless `Shared/Domain` functions without touching the UI.
- **UI Preservation:** The architecture maintains SwiftUI; views just progressively shift their bindings from legacy environment stores to newly decoupled view models.
- **Test-Driven:** Extracting domain logic into pure functions allows us to wrap the existing fragile paths in unit tests before we start rewiring feature views.

## 9. Anti-Patterns to Avoid
- **Coupling Business Logic in View Closures:** No domain rules, scoring, or persistence updates inside `.onTapGesture` or `.onAppear`.
- **Store-as-a-Service-Locator:** Avoid injecting massive global stores merely to access a single property. Use dependency injection to pass only the specific data or closure required.
- **Scattered Truth via `@AppStorage`:** Do not use isolated key-value observation deep inside utility views to govern app-wide logic (like prompt intervals).
- **Orphan / Ghost Flow Routing:** Do not trigger complex route transitions using standalone intent flags wrapped in delayed `DispatchQueue.main.async` timers.
- **Premature Generalization:** Do not create deep inheritances or generic `AIServiceProtocols` without immediate concrete product requirements.
