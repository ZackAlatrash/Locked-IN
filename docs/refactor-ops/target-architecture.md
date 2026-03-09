# LockedIn Refactor Target Architecture

## 1) Purpose and status of this document

**Purpose**
- Define the intended end-state architecture for the LockedIn refactor.
- Provide ticket-authoring constraints so changes remain incremental, behavior-safe, and reviewable.
- Convert Phase 1 audit evidence into concrete architecture rules for this repository.

**Status (as of 2026-03-08)**
- `Effective for planning now`: yes.
- `Immediately enforceable`: selected rules only (marked below).
- `Aspirational end-state`: yes, to be reached through ticketed vertical slices, not a rewrite.

**Evidence base**
- `/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md`
- `/docs/refactor-audit/02_PROJECT_STRUCTURE_AUDIT.md`
- `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`
- `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md`
- `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md`
- `/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md`
- `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md`
- `/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md`
- `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`
- `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- `/docs/refactor-audit/18_OPEN_QUESTIONS_AND_UNCERTAINTIES.md`
- plus concurrency/UI duplication support:
  - `/docs/refactor-audit/06_CONCURRENCY_MAINACTOR_ASYNC_AUDIT.md`
  - `/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md`

---

## 2) Architectural principles for this refactor

1. **Behavior preservation is default**
- No user-visible behavior changes unless explicitly ticketed and justified.

2. **Incremental safety over ideal purity**
- If ideal architecture conflicts with regression risk, choose the smaller safer step and document the tradeoff.

3. **Evidence-based boundaries**
- Tickets must cite concrete audit findings (IDs such as `RB-*`, `ST-*`, `NV-*`, `DP-*`, `TS-*`, `PR-*`).

4. **One main architectural objective per ticket**
- Do not mix navigation + persistence + state rewrites in one step.

5. **Single owner per responsibility**
- Current drift (god view/store + duplicated orchestration) must be reduced by clarifying ownership, not by moving logic randomly.

6. **Reviewability is a hard constraint**
- Changes must be small enough for QC to verify architecture impact and behavior safety.

---

## 3) Current-state summary based on the audit

This is the architecture as implemented today, not desired design.

- **Global mutable store coupling is dominant** (`PlanStore`, `CommitmentSystemStore`) with broad feature mutation access (`01`, `04`, `05`, `07`).
- **God files drive blast radius**: `PlanScreen.swift` (2396 LOC), `PlanStore.swift` (1227), `CommitmentSystemStore.swift` (847) (`03`).
- **Layer boundaries are collapsed**: Views and VMs perform orchestration/domain writes (`RB-01`, `RB-03` in `04`).
- **State duplication exists**: `PlanStore` and `PlanViewModel` mirrored state (`ST-01` in `05`).
- **Navigation ownership is fragmented**: shell overlays + feature sheets + manual router intent consumption (`NV-01..NV-03` in `13`).
- **Persistence ownership is scattered**: startup reset logic, `@AppStorage` spread, sync I/O on `@MainActor`, no migration strategy (`12`, `15`).
- **Test safety net is effectively absent** (`14`, `PR-006`).

Current-state risk concentration: completion flow, plan flow, recovery/check-in arbitration, persistence lifecycle.

---

## 4) Target top-level project structure

Target structure is evolutionary from current tree, not greenfield replacement.

### 4.1 Transitional target (immediately enforceable)

Keep existing top-level directories while enforcing behavior boundaries:

```text
LockedIn/
  App/                    # app composition, dependency wiring, launch policy
  Application/            # transitional orchestrators and legacy stores (decomposition target)
  Core/                   # infrastructure (persistence, logging, utilities, services)
  CoreUI/                 # existing shared UI (transitional; see DesignSystem target)
  Domain/                 # pure domain models/rules/engines
  Features/
    <Feature>/
      Views/
      ViewModels/
      Models/
      UseCases/           # add as slices are introduced
      Repositories/       # feature-facing repository protocols/adapters when needed
  Resources/
```

### 4.2 End-state target (aspirational)

```text
LockedIn/
  App/
  Core/
    Persistence/
    Logging/
    Utilities/
    Services/
  DesignSystem/           # eventual destination of reusable UI from CoreUI/feature duplicates
    Components/
    Styles/
    Themes/
  Domain/
    Entities/
    Rules/
    UseCases/
    Ports/
  Features/
    <Feature>/
      Views/
      ViewModels/
      UseCases/
      Repositories/
      Models/
  Tests/
    UnitTests/
    IntegrationTests/
    UITests/
```

**Tradeoff**
- Do not mass-move folders now. Prefer incremental boundary extraction; rename/move only when a ticket explicitly covers it.

---

## 5) Layer definitions and responsibilities

### Presentation layer
- **Includes**: SwiftUI Views, feature ViewModels.
- **May do**: rendering, local view state, user intent forwarding, view formatting.
- **Must not do**: direct persistence I/O, cross-store orchestration chains, domain rule ownership.

### Application orchestration layer (transitional)
- **Includes**: use-case coordinators, flow coordinators, legacy stores while decomposing.
- **Role**: mediate feature intents into domain operations and repository calls.
- **Constraint**: new orchestration goes into explicit use-case/coordinator units, not into Views.

### Domain layer
- **Includes**: pure entities/rules/engines and use-case contracts.
- **Must be**: framework-light, deterministic where possible, independently testable.

### Data/Persistence layer
- **Includes**: repository implementations and storage adapters in `Core/Persistence`.
- **Role**: read/write durable state, version/migration handling, persistence error mapping.

### Platform/Infrastructure layer
- **Includes**: EventKit providers, logging, clocks, app services.
- **Rule**: accessed through narrow interfaces from application/use-case boundaries.

---

## 6) Dependency direction rules

Target direction:

`View -> ViewModel -> UseCase/FlowCoordinator -> Repository Protocol -> Repository Implementation -> Storage/API`

Rules:
1. Views do not call store mutation chains directly (`RB-01`, `ST` flow traces).
2. Feature ViewModels do not perform direct cross-feature routing side effects; routing goes through defined flow boundary (`NV-03`).
3. Domain rules (e.g., reliability scoring) have one canonical owner, consumed by features (`RB-05`, `PR-011`).
4. `EnvironmentObject` dependencies are minimized and narrowed to feature-safe interfaces over time (`ST-03`, `FD-01`).
5. No new bidirectional dependencies between feature modules.

**Immediately enforceable**
- Any new ticketed logic must follow this dependency direction even if legacy code nearby does not yet.

---

## 7) Feature-boundary rules

1. Each feature owns its UI composition and local interaction state.
2. Cross-feature behavior (completion, plan jump, recovery arbitration) must be mediated by shared orchestration boundaries, not ad hoc direct mutations.
3. A feature should depend on narrow contracts, not full `PlanStore` / `CommitmentSystemStore` surfaces.
4. No feature may introduce a new duplicate implementation of an already-identified shared rule or workflow.
5. Ticket scope should remain within one feature unless shared boundary extraction is the explicit ticket goal.

**Repository-specific priorities**
- Consolidate duplicated completion chain across Cockpit and DailyCheckIn (`FD-02`, `PR-010`).
- Stabilize intent lifecycle for plan focus/edit routing (`NV-02`, `PR-012`).

---

## 8) Shared UI / design system rules

Based on current duplication (`08`):

1. Shared components belong in `CoreUI` now; long-term destination is `DesignSystem`.
2. Extract only **behaviorally duplicated** primitives first:
- top bar action cluster (logs/profile),
- profile sheet presenter,
- toast/warning presenter with explicit cancellation semantics.
3. Do not do broad visual redesign during architectural refactor tickets.
4. Component extraction tickets must preserve current look/interaction unless explicitly ticketed.
5. UI component extraction must not smuggle business logic into shared UI.

**Immediately enforceable**
- New duplication of these known clusters is not allowed.

---

## 9) State ownership rules

1. Every durable or cross-screen state domain has one canonical owner.
2. Mirrored published state (example: `PlanStore` <-> `PlanViewModel`) must be reduced over time through read models or explicit state adapters.
3. Derived UI transient states (toast visibility/timers) should use shared lifecycle-safe mechanisms where possible.
4. No hidden writes to shared state from unrelated layers.
5. `@AppStorage` is configuration access, not business workflow orchestration.

**Current-to-target mapping**
- Current: global mutable stores + mirrored VM state + local timer state.
- Target: explicit ownership + predictable data flow + reduced duplicate mutable projections.

---

## 10) Persistence and storage rules

1. Persistence operations occur behind repository boundaries, not in views.
2. No new destructive startup data reset behavior in production path (`DP-02`, `PR-009`).
3. Introduce persistence schema/versioning strategy incrementally before risky model evolution (`DP-04`, `PR-014`).
4. Standardize persistence error policy (typed errors + structured logging), replacing ad hoc prints (`DP-06`, `PR-015`).
5. Dev-only persistence mutations must be explicitly isolated from production flows.

**Immediately enforceable**
- New persistence writes from presentation layer are disallowed.
- New `print`-based persistence diagnostics in runtime code are disallowed.

---

## 11) Navigation and flow ownership rules

1. AppShell owns global overlay arbitration policy.
2. Features own internal screen-level navigation.
3. Cross-feature route requests use an explicit contract with lifecycle semantics (at-most-once or replace behavior must be defined by ticket).
4. Manual consume patterns are transitional; each migration must increase determinism and testability (`NV-02`, `PR-012`).
5. No ticket may simultaneously redesign shell overlay policy and feature-local sheet structure unless explicitly scoped and test-protected.

**Immediately enforceable**
- New route side effects must go through documented router/coordinator entry points, not arbitrary view callbacks.

---

## 12) Concurrency / MainActor rules

1. `@MainActor` is for UI state publication and coordination, not blocking file I/O.
2. Repository file reads/writes should move off the UI actor through explicit async boundaries (`CC-01`, `CC-02`, `PR-007`) as migration permits.
3. Delayed UI effects must have cancellable ownership (no orphan `Task.sleep` timers in views) (`CC-03`, `PR-013`).
4. Time-based sequencing (`DispatchQueue.main.asyncAfter`) should be replaced by state-driven flow where feasible, in small steps.
5. Concurrency changes are high-risk and require behavior-lock tests first.

**Aspirational note**
- Full actor-boundary cleanup is not immediate; enforce for new/refactored slices first.

---

## 13) Testing expectations by layer

Given `TS-01..TS-04`, test expectations are mandatory in tickets:

### Domain / UseCase
- Unit tests for rule correctness and edge cases.
- Canonical rule tests for shared computations (e.g., reliability).

### Application orchestration (stores/coordinators)
- Behavior-lock tests for mutation chains and recovery paths.
- Integration-style tests for cross-store/cross-feature orchestration.

### Persistence
- Load/save success/failure tests.
- Corrupt/missing data behavior tests.
- Migration/version compatibility tests when schema changes.

### Navigation/flow
- Arbitration tests for overlay precedence.
- Intent lifecycle tests for consume/replace behavior.

### UI
- Focus on snapshot/interaction tests only where behavior logic exists; avoid over-testing pure layout.

**Minimum gate**
- High-risk refactor tickets must specify test strategy explicitly (before, during, or justified deferral with risk).

---

## 14) Migration rules for moving from current state to target state

These rules govern all future implementation tickets.

1. **Use vertical slices**
- One main architectural goal per ticket.
- Keep changes localized to one feature or one shared boundary.

2. **Protect behavior first**
- For high-risk areas with weak tests, create preparatory test or stabilization tickets before structural decomposition.

3. **Prefer adapter introduction over big replacement**
- Add a boundary and migrate one caller path first.
- Keep legacy path until equivalence is proven.

4. **No mega-ticket decomposition**
- Do not refactor `PlanScreen`, `PlanStore`, and `CommitmentSystemStore` together.

5. **Explicitly classify each rule in ticket**
- `Immediately enforceable` vs `aspirational follow-up`.

6. **Preserve runtime semantics during extraction**
- Extract code without changing ordering/side effects unless ticketed.

7. **Traceability**
- Ticket must reference specific audit findings and this document section(s).

8. **Completion discipline**
- Developer summary and QC review must state whether ticket moved code closer to target architecture and what remains.

---

## 15) Explicit non-goals and anti-patterns to avoid

### Non-goals
- No greenfield rewrite.
- No repo-wide renaming/restructuring sweep.
- No architecture “purity pass” that changes behavior silently.
- No broad UI redesign in architecture tickets.

### Anti-patterns
- God-object replacement by another god-object.
- Moving business logic from one view to another view and calling it “refactor.”
- Hidden side-effect changes without tests.
- Introducing new global mutable shared state.
- Refactoring adjacent systems outside ticket scope.

---

## 16) How tickets should use this document

Every ticket must:
1. Cite relevant sections of this document and specific audit findings.
2. Declare current-state problem and target-state movement in concrete terms.
3. Mark constraints as:
- `enforce now` (must comply in this ticket),
- `defer` (explicitly deferred with rationale).
4. Include migration safety plan:
- behavior constraints,
- required tests or justified temporary test gap,
- rollback/containment notes for risky flows.
5. Avoid claiming architecture completion; each ticket should state incremental progress only.

This document is the planning baseline for Instructor, the implementation boundary for Developer, and the verification baseline for QC.
