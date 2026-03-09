# LockedIn Refactor Ownership Rules

## 1) Purpose and status

**Purpose**
- Define strict ownership rules for refactor work so Developer can implement with clear boundaries and QC can review with objective criteria.
- Convert audit findings and target-architecture decisions into enforceable ownership constraints.

**Status (2026-03-08)**
- `Planning baseline`: active.
- `Implementation enforcement`: active for new/refactored code.
- `Legacy code`: may remain temporarily under controlled exceptions defined below.

---

## 2) Scope of these rules

These rules govern ownership of:
- UI behavior and presentation logic,
- state and mutation boundaries,
- domain/business rules,
- persistence and storage operations,
- navigation/flow decisions,
- shared UI extraction,
- cross-feature orchestration.

These rules apply to all refactor tickets and reviews under `/docs/refactor-ops/`.

---

## 3) Rule levels

### Absolute ownership rules
- Non-negotiable for any new/refactored slice.
- Violations are QC `Fail` unless ticket explicitly authorizes behavior change and mitigation.

### Preferred ownership patterns
- Default target for incremental migration.
- May be deferred only when explicitly documented in ticket constraints.

### Transitional exceptions
- Temporary allowances for legacy hotspots.
- Must include scope limit, risk note, and removal trigger in ticket/completion notes.

---

## 4) Absolute ownership rules

### A. Views

`OR-A01` Views own rendering and event forwarding only.
- Allowed: layout, styling, local transient UI state.
- Not allowed: business-rule evaluation, persistence writes, multi-store mutation chains.
- Audit basis: `RB-01`, `SF-01`, `DP-03`, `NV-03`.

`OR-A02` Views must not be source-of-truth for cross-screen durable state.
- `@State` is local UI state only.
- Durable behavior state must be owned by a state owner/use-case boundary.

`OR-A03` Views must not directly invoke repository/storage APIs.
- No direct `UserDefaults`, JSON repository, disk or EventKit persistence writes from feature views.

### B. Presentation/state owners (ViewModels, coordinators, transitional stores)

`OR-A04` Each state domain must have one canonical mutable owner.
- No parallel writable mirrors (example risk: `PlanStore` + `PlanViewModel` mirrored `@Published` state).
- Audit basis: `ST-01`.

`OR-A05` ViewModels may orchestrate feature-local UI behavior but not cross-feature side-effect chains directly.
- Cross-feature completion, recovery sync, or route side effects must go through explicit use-case/coordinator boundaries.
- Audit basis: `FD-02`, `NV-03`, `SF-02`.

`OR-A06` New global `EnvironmentObject` coupling is prohibited unless scoped by ticket and narrowed interface.
- Full-store dependency injection into additional features is disallowed by default.
- Audit basis: `FD-01`, `ST-03`.

### C. Domain/use-case logic

`OR-A07` Canonical business rules must have one owner.
- Reliability scoring, completion side effects, and reconciliation policies cannot be duplicated across feature VMs/views.
- Audit basis: `RB-05`, `PR-010`, `PR-011`.

`OR-A08` Cross-feature workflows must be owned by explicit orchestration boundaries.
- Completion flow (`recordCompletionDetailed -> reconcileAfterCompletion -> integrity tick`) cannot remain duplicated per entry point when touched by refactor tickets.

### D. Repositories/persistence

`OR-A09` Persistence ownership belongs to repository/storage boundaries, not presentation.
- Views/ViewModels cannot become persistence coordinators.

`OR-A10` New destructive startup reset behaviors in production paths are forbidden.
- Startup data wipe logic cannot be expanded.
- Audit basis: `DP-02`, `PR-009`.

`OR-A11` New persistence error handling via `print` is forbidden.
- Use typed error propagation and structured logging policy.
- Audit basis: `DP-06`, `PR-015`.

### E. Navigation and flow ownership

`OR-A12` Global overlay arbitration belongs to AppShell boundary.
- Recovery vs daily-check-in precedence is shell-owned policy; feature screens must not override it ad hoc.
- Audit basis: `NV-01`.

`OR-A13` Cross-feature route requests must use documented router/coordinator entrypoints.
- No new direct tab/intent mutation from random utility/helpers.
- Audit basis: `NV-02`, `NV-03`.

`OR-A14` Ticket scope must not mix navigation-contract redesign with store decomposition in the same slice.
- Safety constraint from priority map and architecture rules.

### F. Shared UI/design system extraction

`OR-A15` Shared UI components must not own business logic or persistence behavior.
- Shared components are presentational primitives only.

`OR-A16` New duplication in known shared clusters is disallowed.
- Top bar actions, profile sheet wrappers, and transient toast containers should be extracted/reused, not copied.
- Audit basis: UI duplication cluster in `08`.

### G. Cross-feature orchestration

`OR-A17` Cross-feature orchestration ownership must be explicit and singular.
- One boundary per workflow type (completion orchestration, overlay arbitration, intent lifecycle).
- Duplicate orchestration implementations are forbidden in new/refactored paths.

`OR-A18` Cross-feature orchestration changes require behavior-lock test strategy in ticket.
- If tests are missing, preparatory ticket is required before high-risk ownership moves.

---

## 5) Preferred ownership patterns

`OR-P01` Feature entry pattern
- `View -> ViewModel -> UseCase/Coordinator -> Repository Protocol`.

`OR-P02` Feature contracts over full stores
- Prefer narrow read/write protocols per feature use-case over injecting full `PlanStore`/`CommitmentSystemStore`.

`OR-P03` Read model adapters instead of mirrored mutable state
- When legacy store remains canonical, ViewModel should expose transformed read model, not duplicate writable fields.

`OR-P04` State-driven UI effects
- Prefer cancellable, state-owned task semantics over scattered `Task.sleep`/`DispatchQueue.main.asyncAfter`.

`OR-P05` Shared behavioral UI primitives first
- Prioritize extraction where duplication carries behavior differences (toast timing/modal wrappers), not cosmetic-only dedup.

---

## 6) Transitional exceptions during migration

These are temporary allowances, not target architecture.

`OR-T01` Legacy store direct usage may remain in untouched code paths.
- Allowed only when ticket scope is elsewhere.
- Not allowed to expand in new files/callers without explicit ticket exception.

`OR-T02` Manual router intent consume pattern may remain while stabilizing semantics.
- Any ticket touching intent flow must document chosen lifecycle semantics and regression checks.

`OR-T03` Mixed ownership in `PlanStore` / `CommitmentSystemStore` may persist between decomposition slices.
- Tickets must extract one responsibility at a time and keep behavior parity.

`OR-T04` Existing `@AppStorage` usage may remain until prompt-state boundary is introduced.
- New writes for the same behavioral keys from additional surfaces are disallowed.

`OR-T05` MainActor-bound synchronous persistence may remain in untouched code.
- Tickets introducing/refactoring persistence paths should avoid adding new blocking I/O on UI actor and document follow-up if full move is deferred.

**Exception expiry rule**
- Each ticket using a transitional exception must include:
  - exception ID,
  - why needed,
  - risk,
  - removal trigger (next planned ownership step).

---

## 7) Rules by area

### 7.1 Views
- Follow `OR-A01`..`OR-A03`, `OR-A15`.
- View-level handlers can call ViewModel/use-case intents only.
- View cannot directly coordinate store+router+persistence chain.

### 7.2 Presentation/state owners
- Follow `OR-A04`..`OR-A06`, `OR-P03`.
- ViewModel state must represent UI projection, not duplicate durable source ownership.

### 7.3 Domain/use-case logic
- Follow `OR-A07`, `OR-A08`, `OR-A17`.
- Shared business rules live in domain/use-case boundary, not per-screen helper logic.

### 7.4 Repositories/persistence
- Follow `OR-A09`..`OR-A11`.
- Data lifecycle policy changes (reset/migration/failure strategy) must be explicit in ticket.

### 7.5 Navigation and flow ownership
- Follow `OR-A12`..`OR-A14`.
- Route intent lifecycle changes require deterministic behavior spec and test plan.

### 7.6 Shared UI/design system extraction
- Follow `OR-A15`, `OR-A16`, `OR-P05`.
- Shared primitives accept data/actions; they do not fetch/mutate domain state.

### 7.7 Cross-feature orchestration
- Follow `OR-A17`, `OR-A18`.
- Completion, recovery synchronization, and check-in prompt arbitration are top-priority orchestration boundaries.

---

## 8) Anti-patterns to reject

Reject in ticket planning, implementation, and QC:
- Moving business logic from one View to another View and labeling it refactor.
- Adding new feature dependencies on full global stores by convenience.
- Duplicating completion/reliability rule logic in multiple feature layers.
- Introducing new presentation-level persistence writes for behavioral state.
- Combining plan screen split, store decomposition, and navigation contract changes in one ticket.
- Introducing hidden behavior changes without explicit ticket constraints and tests.

---

## 9) How tickets should reference ownership rules

Every ticket should include an `Ownership Rules` subsection with:
1. `Rules enforced now`: list applicable `OR-A*` and `OR-P*`.
2. `Transitional exceptions`: list `OR-T*` used (if any), with risk and removal trigger.
3. `Ownership movement`: current owner -> target owner for each touched concern.
4. `QC checks`: concrete assertions QC can validate against these rule IDs.

Minimum QC ownership verdict guidance:
- `Pass`: no `OR-A*` violations; exceptions documented and bounded.
- `Conditional Pass`: minor `OR-P*` misses with clear follow-up.
- `Fail`: any unapproved `OR-A*` violation or undocumented exception.

---

## 10) Alignment references

This document operationalizes:
- `/docs/refactor-ops/architecture-rules.md`
- `/docs/refactor-ops/target-architecture.md`
- `/docs/refactor-ops/decision-log.md` (`AD-001`..`AD-014`)
- Phase 1 audits, especially `04`, `05`, `07`, `12`, `13`, `16`.
