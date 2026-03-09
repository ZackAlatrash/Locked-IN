# LockedIn Responsibility Mapping

## Purpose

Provide an implementation and review map from concern -> owner for LockedIn refactor work.
This mapping is repository-specific and grounded in audited ownership failures.

Use this with:
- `/docs/refactor-ops/ownership-rules.md`
- `/docs/refactor-ops/target-architecture.md`
- `/docs/refactor-ops/decision-log.md`

---

## 1) Concern-to-owner mapping

| Concern | Current state (audit) | Target owner (strict) | Transitional acceptable owner | Must not own | Audit anchors |
|---|---|---|---|---|---|
| Completion side-effect chain (complete -> reconcile -> integrity tick) | Duplicated across `CockpitView` and `DailyCheckInViewModel` | Shared completion use-case/coordinator boundary | Existing path may remain in untouched caller while first caller migrates | Views, unrelated feature VMs | `RB-01`, `FD-02`, `SF-01`, `PR-010` |
| Reliability score computation | Divergent formulas in Cockpit VM vs DailyCheckIn VM | Single domain rule/use-case | One legacy formula may remain until canonical rule is introduced and adopted | Multiple feature VMs simultaneously | `RB-05`, `PR-011`, `AD-007` |
| Plan allocation mutation + validation + projection | Overloaded `PlanStore` | Decomposed use-cases + plan state owner with narrow interfaces | `PlanStore` remains canonical during stepwise extraction | `PlanScreen` / feature views | `RB-02`, `ST-01`, `PR-002`, `PR-001` |
| Commitment mutation + recovery transitions + logging aggregation | Overloaded `CommitmentSystemStore` | Decomposed use-cases + commitment state owner | `CommitmentSystemStore` remains canonical during stepwise extraction | Views / UI helpers | `RB-02`, `SF-02`, `PR-003` |
| Recovery vs daily-check-in popup arbitration | Shell logic in `MainAppView` | AppShell flow coordinator policy boundary | Current shell logic while semantics are formalized | Feature screens owning global precedence | `NV-01`, `NV-03`, `PR-012`, `AD-006` |
| Plan focus/edit route intent lifecycle | Manual intent consume in `AppRouter` + `PlanScreen` | Explicit route intent contract (consume semantics defined) | Existing router consume pattern until stabilized | Ad hoc intent clearing in unrelated views | `NV-02`, `FD-03`, `AD-006` |
| Daily check-in prompt settings persistence | Writes from shell, profile, dev options | Single prompt-settings boundary (repository/use-case + shell consumer) | Existing keys in shell/profile until boundary added | Additional new writers in feature views | `SF-03`, `DP-03`, `PR-008` |
| Startup reset behavior | Destructive reset in app root path | Explicit lifecycle policy boundary (non-destructive by default) | Existing legacy behavior unchanged unless explicitly ticketed | New destructive startup paths | `DP-02`, `PR-009`, `UQ-01`, `AD-009` |
| Persistence read/write operations | Stores + repositories with sync I/O on MainActor | Repository/persistence layer behind async-aware boundaries | Existing repository path while incremental async isolation proceeds | Views/VMs directly performing persistence | `DP-01`, `DP-06`, `PR-007`, `AD-008` |
| Profile modal presentation wiring | Duplicated in Cockpit/Plan/Logs | Shared presentational component/presenter | Existing duplicated wrappers until extraction ticket | Business logic owners | `08 UI-02`, `AD-010` |
| Top-bar actions (logs/profile controls) | Duplicated across major screens | Shared presentational primitive | Existing duplicates until extracted | Domain/persistence layers | `08 UI-01`, `AD-010` |
| Toast/warning transient behavior | Duplicated timing logic in Cockpit/Plan/DailyCheckIn | Shared transient feedback presenter contract with cancellable ownership | Existing local toasts while migrating flow-by-flow | Domain/persistence owners | `ST-02`, `08 UI-03`, `PR-013`, `AD-011` |
| Cross-feature flow handoff (e.g., DailyCheckIn -> Plan) | Direct router calls in feature VM/view | Dedicated flow coordinator contract | Existing router calls until ticket formalizes contract | Arbitrary helper/services mutating route state | `NV-03`, `FD-03`, `AD-006` |
| Dev data wipes and scenario seeding | `DevOptionsController` mutates production stores/defaults | Debug-only boundary isolated from production behavior contracts | Existing dev tools in place, no expansion into production paths | Core runtime screens | `RB-04`, `DP-03`, `PR-008` |

---

## 2) Practical placement examples (should live here)

### Example A: Completion orchestration
- **Should live in**: shared completion use-case/coordinator in application/domain boundary.
- **Why**: same workflow triggered by Cockpit and DailyCheckIn must remain behaviorally consistent.

### Example B: Reliability score
- **Should live in**: canonical domain rule/service (single formula owner).
- **Why**: avoid contradictory UI metrics across features.

### Example C: Plan deep-link intent lifecycle
- **Should live in**: explicit routing contract (router/coordinator), with deterministic consume semantics.
- **Why**: prevent dropped/duplicate intents during tab/screen timing shifts.

### Example D: Prompt settings writes
- **Should live in**: one prompt settings boundary (repository/use-case), consumed by shell/profile/dev flows.
- **Why**: remove distributed `@AppStorage` behavior drift.

### Example E: Toast presentation behavior
- **Should live in**: shared presentational helper with explicit cancellation ownership.
- **Why**: eliminate stale delayed updates and timing divergence.

---

## 3) Practical placement examples (must not live here)

### Example F: Completion logic in View tap handlers
- **Must not live in**: `CockpitView.perform(_:)` style UI handlers.
- **Reason**: view-layer orchestration/multi-store mutation violates `OR-A01`, `OR-A17`.

### Example G: Canonical scoring logic in multiple ViewModels
- **Must not live in**: both Cockpit and DailyCheckIn VMs concurrently as separate formulas.
- **Reason**: ownership split creates inconsistent behavior and drift.

### Example H: Durable behavior key writes scattered across screens
- **Must not live in**: unrelated views each writing prompt-policy keys.
- **Reason**: no single owner for persistent behavior state.

### Example I: New persistence writes from feature view models/views
- **Must not live in**: presentation layer.
- **Reason**: violates persistence isolation and increases lifecycle fragility.

### Example J: Global route precedence decisions inside feature screens
- **Must not live in**: feature-specific views deciding recovery vs check-in overlay priority.
- **Reason**: global flow ownership belongs to shell flow boundary.

---

## 4) Repo-specific known problem-area mappings

### 4.1 Cockpit completion path
- Current hotspot: `CockpitView` mutates stores and routing in one handler.
- Required ownership move: Cockpit intent -> Cockpit VM/use-case boundary -> shared completion orchestrator.
- Transitional note: existing direct path may remain if ticket scope is elsewhere.

### 4.2 DailyCheckIn completion path
- Current hotspot: `DailyCheckInViewModel` performs reconciliation, regulator run, route trigger.
- Required ownership move: DailyCheckIn intent -> shared completion orchestrator + route contract.
- Transitional note: keep behavior identical until parity tests exist.

### 4.3 Plan feature state ownership
- Current hotspot: `PlanViewModel` mirrors `PlanStore` mutable state.
- Required ownership move: one canonical mutable owner with read model adapter for UI.
- Transitional note: mirror state can persist temporarily but cannot expand.

### 4.4 AppShell popup arbitration
- Current hotspot: shell contains intertwined checks/triggers for recovery and check-in overlays.
- Required ownership move: explicit shell arbitration policy component with defined precedence and tests.
- Transitional note: existing shell logic remains until policy contract ticket.

### 4.5 Persistence lifecycle
- Current hotspot: startup reset behavior + distributed `@AppStorage` + sync MainActor I/O.
- Required ownership move: centralized persistence policy + prompt settings boundary + async-aware repository boundaries.
- Transitional note: no expansion of destructive or distributed patterns while migrating.

---

## 5) QC review checklist mapped to ownership

Use this per ticket:

1. Does the change introduce any new owner violating `OR-A*` rules?
2. Are touched concerns mapped to target owner in Section 1?
3. If transitional owner remains, is exception explicitly documented with removal trigger?
4. Did implementation reduce or expand coupling to `PlanStore` / `CommitmentSystemStore`?
5. Did navigation changes preserve shell-vs-feature ownership split?
6. Did persistence-related edits keep writes out of views and avoid new destructive startup behavior?

QC grading guidance:
- `Pass`: ownership movement is correct or neutral and no new absolute-rule violations.
- `Conditional Pass`: ownership correct but incomplete exception documentation.
- `Fail`: new ownership drift, undocumented exceptions, or absolute-rule violations.

---

## 6) Ticket authoring guidance using this mapping

Each ticket should include:
1. `Concern(s) touched` (from mapping table).
2. `Current owner -> Target owner` statements.
3. `Absolute rules enforced` (`OR-A*` IDs).
4. `Transitional exceptions used` (`OR-T*` IDs) and removal trigger.
5. `Behavior-safety tests` required for ownership move.

Do not create tickets that move multiple high-risk concerns in one pass (navigation + store decomposition + persistence lifecycle).
