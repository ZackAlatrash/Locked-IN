# LockedIn Refactor Backlog

## 1. Purpose and how to use the backlog

This backlog is the unified sequencing document for future refactor tickets. It translates the audit, target architecture, ownership rules, decision log, ledger, and completed work into a practical ticket queue for this repository.

Use it to:
- choose the next smallest safe ticket,
- confirm prerequisites before planning risky work,
- avoid giant rewrites and mixed-concern tickets,
- keep ticket sizing consistent with workflow rules,
- select up to two non-overlapping tickets when parallel execution is safe.

Backlog rules:
- This is not a brainstorm list.
- Each item should be small enough to become one real implementation ticket later.
- Higher-risk structural work must stay behind the required safety and ownership preparation.
- Review verdicts and the ledger take precedence over stale ticket status.
- Parallel selection is opt-in, not default.

### Parallel planning note

Parallel ticket selection should work like this:
1. Start with the highest-priority `ready` ticket.
2. Pair it only with another `ready` ticket that is explicitly listed in both items' `Can Run With` fields.
3. Treat `Must Not Overlap With` as a hard stop even if the tickets are in different phases.
4. If both candidate tickets would require `LockedIn.xcodeproj/project.pbxproj` edits, treat the pair as sequential unless one ticket can be completed without project-file changes.
5. Prefer one architecture-safety ticket plus one isolated build-integrity or low-risk UI ticket.

Safe ticket pair types in this repo:
- test or contract work paired with isolated release-integrity cleanup,
- unrelated presentational splits in different screens,
- unrelated feature cleanup paired with one store or persistence ticket that does not touch the same boundary.

Tickets that must stay sequential:
- any pair touching the same screen, store, or view model ownership boundary,
- shared-boundary extraction followed by caller migration,
- navigation-contract work paired with adjacent navigation/overlay work,
- persistence schema/reset work paired with other persistence-boundary edits,
- two tickets that both need the same `project.pbxproj` or target-membership edits.

---

## 2. Current progress summary

Current state:
- `RF-001` completed: shared profile sheet container extracted for Plan + Logs.
- `RF-002` completed: shared logs/profile toolbar actions extracted for Plan + Logs.
- `RF-003` completed: `LockedInTests` target and baseline test support added.
- `RF-004` completed: `PlanStore` behavior-lock tests added.
- `RF-005` completed: `CommitmentSystemStore` behavior-lock tests added.

What that means:
- The workflow is validated on both low-risk UI extraction and safety-foundation testing.
- `PlanStore` and `CommitmentSystemStore` now have baseline deterministic regression protection.
- The next high-value gate is cross-feature completion parity plus isolated release/build integrity cleanup.
- Large structural work is still intentionally held behind the remaining flow and ownership prep.

---

## 3. Active / near-term phase

## Phase A — Safety Foundation and Release Integrity

### RF-001 — Profile Sheet Container Extraction (Plan + Logs)
- Short objective: remove duplicated profile sheet wrapper into one shared CoreUI component.
- Why it matters: validated the workflow with a low-blast, behavior-preserving shared UI extraction.
- Primary reference: `/docs/refactor-ops/refactor-ledger.md`, `/docs/refactor-ops/ownership-rules.md` (`OR-A15`, `OR-A16`)
- Dependency note: none.
- Parallel Group: `PG-COMPLETED-UI`
- Can Run With: `n/a (completed)`
- Must Not Overlap With: `n/a (completed)`
- Status: `completed`

### RF-002 — Toolbar Actions Extraction (Plan + Logs)
- Short objective: remove duplicated logs/profile toolbar cluster into one shared CoreUI component.
- Why it matters: further validated shared UI ownership without touching router/store/persistence layers.
- Primary reference: `/docs/refactor-ops/refactor-ledger.md`, `/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md`
- Dependency note: none.
- Parallel Group: `PG-COMPLETED-UI`
- Can Run With: `n/a (completed)`
- Must Not Overlap With: `n/a (completed)`
- Status: `completed`

### RF-003 — Add LockedIn Test Target and Baseline Test Support
- Short objective: create the first test target and minimum test support needed for behavior-lock tests.
- Why it matters: the audit identifies total absence of meaningful automated safety coverage as the top refactor blocker.
- Primary reference: `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-01`..`TS-04`), `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- Dependency note: prerequisite for all behavior-lock testing tickets below.
- Parallel Group: `PG-COMPLETED-TEST-INFRA`
- Can Run With: `n/a (completed)`
- Must Not Overlap With: `n/a (completed)`
- Status: `completed`

### RF-004 — PlanStore Behavior-Lock Tests for Allocation Placement and Reconciliation
- Short objective: add focused tests for `PlanStore` placement validation, move/remove behavior, draft apply, and reconcile-after-completion.
- Why it matters: `PlanStore` is a critical god store and a primary blast-radius source.
- Primary reference: `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`, `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-002`)
- Dependency note: depended on `RF-003`.
- Parallel Group: `PG-COMPLETED-PLAN-TESTS`
- Can Run With: `n/a (completed)`
- Must Not Overlap With: `n/a (completed)`
- Status: `completed`

### RF-005 — CommitmentSystemStore Behavior-Lock Tests for Recovery and Daily Integrity Tick
- Short objective: add deterministic tests for recovery transitions and daily integrity behavior.
- Why it matters: `CommitmentSystemStore` is a critical domain/persistence hotspot with silent regression risk.
- Primary reference: `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`, `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-003`)
- Dependency note: depended on `RF-003`.
- Parallel Group: `PG-COMPLETED-COMMITMENT-TESTS`
- Can Run With: `n/a (completed)`
- Must Not Overlap With: `n/a (completed)`
- Status: `completed`

### RF-006 — Cross-Feature Completion Parity Tests for Cockpit and DailyCheckIn
- Short objective: add integration-style tests confirming the two completion entry points produce equivalent side effects.
- Why it matters: duplicated completion orchestration is an active divergence risk and a planned consolidation target.
- Primary reference: `/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md` (`FD-02`), `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-02`)
- Dependency note: depends on completed `RF-003`, `RF-004`, and `RF-005`.
- Parallel Group: `PG-A-COMPLETION-SAFETY`
- Can Run With: `RF-007`, `RF-008`
- Must Not Overlap With: `RF-009`, `RF-010`, `RF-011`, `RF-020`, `RF-026`
- Status: `ready`

### RF-007 — Repair Stale Project File Reference
- Short objective: remove or repair the missing `IdentityWarningViewModel.swift` reference in `project.pbxproj`.
- Why it matters: project metadata drift is a build-integrity risk and a small, isolated cleanup candidate.
- Primary reference: `/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md` (problem 9), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-005`)
- Dependency note: independent cleanup; keep limited to project metadata repair.
- Parallel Group: `PG-A-BUILD-INTEGRITY`
- Can Run With: `RF-006`, `RF-012`
- Must Not Overlap With: `RF-008`, `RF-009`, `RF-010`
- Status: `ready`

### RF-008 — Remove Simulation Files from App Target Membership
- Short objective: isolate simulation entry points from the production app target.
- Why it matters: release-target contamination is marked critical and can be reduced without touching runtime behavior.
- Primary reference: `/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md` (problem 8), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-004`)
- Dependency note: independent; should stay narrowly limited to target membership and build config.
- Parallel Group: `PG-A-RELEASE-INTEGRITY`
- Can Run With: `RF-006`, `RF-012`
- Must Not Overlap With: `RF-007`, `RF-009`, `RF-023`
- Status: `ready`

---

## 4. Next phases in priority order

## Phase B — Flow Stabilization and Ownership Protection

### RF-009 — Shell Overlay Arbitration Tests
- Short objective: add tests for recovery-popup precedence over daily-check-in popup.
- Why it matters: navigation and overlay ownership is fragmented and currently unprotected.
- Primary reference: `/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md` (`NV-01`), `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-03`)
- Dependency note: safety prerequisites are complete; should land before overlay-policy refactors.
- Parallel Group: `PG-B-SHELL-OVERLAY`
- Can Run With: `RF-013`, `RF-028`
- Must Not Overlap With: `RF-006`, `RF-007`, `RF-008`, `RF-010`, `RF-012`
- Status: `ready`

### RF-010 — Extract Completion Orchestration Boundary for Cockpit Path
- Short objective: introduce one shared completion use-case/coordinator and migrate the Cockpit entry path only.
- Why it matters: enforces ownership rules without attempting a two-caller migration at once.
- Primary reference: `/docs/refactor-ops/ownership-rules.md` (`OR-A08`, `OR-A17`), `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-01`)
- Dependency note: depends on `RF-006`; keep as one-caller migration only.
- Parallel Group: `PG-B-COMPLETION-BOUNDARY`
- Can Run With: `RF-028`
- Must Not Overlap With: `RF-007`, `RF-009`, `RF-011`, `RF-020`, `RF-026`
- Status: `blocked`

### RF-011 — Migrate DailyCheckIn Completion Path to Shared Completion Boundary
- Short objective: move the DailyCheckIn completion path to the same orchestrator introduced in `RF-010`.
- Why it matters: removes duplicated workflow ownership across features.
- Primary reference: `/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md` (`FD-02`), `/docs/refactor-ops/decision-log.md` (`AD-007`)
- Dependency note: depends on `RF-010`; must stay separate from the extraction ticket.
- Parallel Group: `PG-B-COMPLETION-MIGRATION`
- Can Run With: `RF-029`
- Must Not Overlap With: `RF-006`, `RF-010`, `RF-020`, `RF-026`
- Status: `blocked`

### RF-012 — Define and Test Plan Route Intent Lifecycle Semantics
- Short objective: make `AppRouter` plan focus/edit intent lifecycle explicit and testable without broad navigation redesign.
- Why it matters: manual consume semantics are timing-sensitive and create dropped or duplicate route risk.
- Primary reference: `/docs/refactor-audit/13_NAVIGATION_FLOW_AND_SCREEN_OWNERSHIP_AUDIT.md` (`NV-02`), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-012`)
- Dependency note: safety prerequisites are complete; should precede `PlanScreen` navigation extraction.
- Parallel Group: `PG-B-PLAN-ROUTING`
- Can Run With: `RF-007`, `RF-008`, `RF-013`
- Must Not Overlap With: `RF-009`, `RF-014`, `RF-016`, `RF-017`
- Status: `ready`

### RF-013 — Centralize Daily Check-In Prompt Settings Writes
- Short objective: introduce one prompt-settings boundary and remove distributed ownership of prompt-related `@AppStorage` writes.
- Why it matters: durable behavioral state is currently mutated from shell, profile, and dev tools.
- Primary reference: `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-03`), `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`SF-03`)
- Dependency note: keep separate from overlay-arbitration work and startup-reset work.
- Parallel Group: `PG-B-PROMPT-SETTINGS`
- Can Run With: `RF-009`, `RF-012`
- Must Not Overlap With: `RF-008`, `RF-023`, `RF-024`
- Status: `ready`

## Phase C — Plan Feature Structural Decomposition

### RF-014 — Extract PlanScreen Toast / Undo Presenter
- Short objective: isolate transient toast and undo presentation from `PlanScreen` into a dedicated presentational component or local presenter boundary.
- Why it matters: `PlanScreen` is the largest UI hotspot and toast timing logic is duplicated and brittle.
- Primary reference: `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md` (`PlanScreen`), `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`ST-02`)
- Dependency note: safer after `RF-009` and `RF-012`.
- Parallel Group: `PG-C-PLANSCREEN-TOAST`
- Can Run With: `RF-029`, `RF-030`
- Must Not Overlap With: `RF-012`, `RF-015`, `RF-016`, `RF-017`, `RF-027`
- Status: `future`

### RF-015 — Extract PlanScreen Legend / Status Section
- Short objective: split a purely presentational section from `PlanScreen` without touching state or navigation.
- Why it matters: begins reducing `PlanScreen` size along low-risk boundaries.
- Primary reference: `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`, `/docs/refactor-ops/target-architecture.md` (migration rules)
- Dependency note: can proceed after early flow stabilization if the section remains truly presentational.
- Parallel Group: `PG-C-PLANSCREEN-PRESENTATION`
- Can Run With: `RF-029`, `RF-030`
- Must Not Overlap With: `RF-014`, `RF-016`, `RF-017`
- Status: `future`

### RF-016 — Replace PlanViewModel Mirrored Mutable State with Read-Model Adapter
- Short objective: reduce duplicated writable state between `PlanStore` and `PlanViewModel`.
- Why it matters: state duplication is a known desynchronization hazard.
- Primary reference: `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`ST-01`), `/docs/refactor-ops/ownership-rules.md` (`OR-A04`, `OR-P03`)
- Dependency note: depends on completed `RF-004`; do not mix with `PlanStore` decomposition.
- Parallel Group: `PG-C-PLAN-STATE-OWNERSHIP`
- Can Run With: `RF-020`, `RF-028`
- Must Not Overlap With: `RF-012`, `RF-014`, `RF-015`, `RF-017`, `RF-018`, `RF-019`
- Status: `future`

### RF-017 — Extract PlanScreen Calendar Permission Flow Boundary
- Short objective: isolate calendar permission and request flow from `PlanScreen` and `PlanViewModel` into a narrow service or use-case boundary.
- Why it matters: reduces cross-layer responsibilities in a risky screen without changing planning logic.
- Primary reference: `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`, `/docs/refactor-ops/target-architecture.md` (layer definitions)
- Dependency note: after `RF-012`; keep separate from board and queue extraction.
- Parallel Group: `PG-C-PLAN-CALENDAR`
- Can Run With: `RF-020`, `RF-030`
- Must Not Overlap With: `RF-014`, `RF-015`, `RF-016`, `RF-025`
- Status: `future`

## Phase D — Store Responsibility Decomposition

### RF-018 — Extract PlanStore Persistence Adapter Boundary
- Short objective: separate persistence read and write concerns from `PlanStore` mutation and projection logic.
- Why it matters: `PlanStore` mixes domain, persistence, and UI-warning responsibilities.
- Primary reference: `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-02`), `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-01`)
- Dependency note: depends on completed `RF-004`; should precede async I/O migration.
- Parallel Group: `PG-D-PLANSTORE-PERSISTENCE`
- Can Run With: `RF-029`, `RF-030`
- Must Not Overlap With: `RF-016`, `RF-019`, `RF-022`, `RF-023`, `RF-024`, `RF-025`
- Status: `future`

### RF-019 — Extract PlanStore Projection Builder Boundary
- Short objective: separate projection-building and read-model logic from `PlanStore` mutation logic.
- Why it matters: reduces god-store breadth without changing storage semantics.
- Primary reference: `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-02`), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-002`)
- Dependency note: depends on completed `RF-004`; do not combine with persistence extraction.
- Parallel Group: `PG-D-PLANSTORE-PROJECTION`
- Can Run With: `RF-028`, `RF-029`, `RF-030`
- Must Not Overlap With: `RF-016`, `RF-018`, `RF-022`, `RF-025`
- Status: `future`

### RF-020 — Extract CommitmentSystemStore Recovery Transition Boundary
- Short objective: isolate recovery transition rules from the rest of `CommitmentSystemStore`.
- Why it matters: recovery flow is critical, cross-feature, and currently coupled to persistence and log aggregation.
- Primary reference: `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`SF-02`), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-003`)
- Dependency note: depends on completed `RF-005`; should precede broader commitment-store decomposition.
- Parallel Group: `PG-D-COMMITMENT-RECOVERY`
- Can Run With: `RF-016`, `RF-017`, `RF-028`, `RF-029`
- Must Not Overlap With: `RF-006`, `RF-010`, `RF-011`, `RF-021`, `RF-022`, `RF-026`
- Status: `future`

### RF-021 — Replace Runtime Print Statements with Structured Logging in Stores
- Short objective: replace production `print` diagnostics in runtime stores with structured logging.
- Why it matters: low-to-medium risk hygiene improvement that also clarifies persistence failure policy.
- Primary reference: `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-015`), `/docs/refactor-ops/target-architecture.md` (persistence rules)
- Dependency note: can follow after store test coverage exists; keep separate from store boundary extraction.
- Parallel Group: `PG-D-STORE-LOGGING`
- Can Run With: `RF-028`, `RF-029`, `RF-030`
- Must Not Overlap With: `RF-020`, `RF-022`, `RF-024`
- Status: `future`

## Phase E — Persistence Hardening and Runtime Safety

### RF-022 — Add Persistence Failure Path Tests for JSON Repositories
- Short objective: cover load and save failure behavior plus current warning and error semantics.
- Why it matters: persistence failure handling is weak and currently under-tested.
- Primary reference: `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-06`), `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-04`)
- Dependency note: depends on completed `RF-003`; safer after `RF-018` or `RF-019` boundaries are clarified.
- Parallel Group: `PG-E-PERSISTENCE-FAILURE-TESTS`
- Can Run With: `RF-029`, `RF-030`
- Must Not Overlap With: `RF-018`, `RF-019`, `RF-020`, `RF-021`, `RF-023`, `RF-024`
- Status: `future`

### RF-023 — Clarify and Isolate Startup Reset Policy
- Short objective: convert startup destructive reset behavior into an explicit, documented boundary or remove it from the production path once policy is confirmed.
- Why it matters: current startup reset behavior is critical-risk and intent is still partially uncertain.
- Primary reference: `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-02`), `/docs/refactor-ops/decision-log.md` (`AD-009`)
- Dependency note: blocked on product and intent clarification; should not proceed as a silent behavior change.
- Parallel Group: `PG-E-STARTUP-RESET-POLICY`
- Can Run With: `none (sequential and policy-blocked)`
- Must Not Overlap With: `RF-008`, `RF-013`, `RF-018`, `RF-022`, `RF-024`
- Status: `blocked`

### RF-024 — Add Schema Versioning Envelope for JSON Persistence
- Short objective: introduce a versioned persistence envelope without broad model rewrites.
- Why it matters: current JSON storage has no explicit migration path.
- Primary reference: `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-04`), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-014`)
- Dependency note: depends on persistence tests; safer after `RF-018` and `RF-022`.
- Parallel Group: `PG-E-SCHEMA-VERSIONING`
- Can Run With: `RF-028`
- Must Not Overlap With: `RF-013`, `RF-018`, `RF-021`, `RF-022`, `RF-023`, `RF-025`
- Status: `future`

### RF-025 — Stabilize PlanCalendarEvent Identity
- Short objective: replace per-fetch random UUID generation with stable event identity mapping.
- Why it matters: random IDs risk diffing glitches and state restoration issues.
- Primary reference: `/docs/refactor-audit/12_DATA_PERSISTENCE_AND_STORAGE_AUDIT.md` (`DP-05`)
- Dependency note: independent of major store decomposition, but must stay separate from Plan calendar permission and PlanStore persistence work.
- Parallel Group: `PG-E-CALENDAR-IDENTITY`
- Can Run With: `RF-029`, `RF-030`
- Must Not Overlap With: `RF-017`, `RF-018`, `RF-019`, `RF-024`
- Status: `future`

---

## 5. Deferred / future items

### RF-026 — Canonical Reliability Score Source
- Short objective: define one canonical reliability computation source and migrate consumers.
- Why it matters: Cockpit and DailyCheckIn currently show different formulas for the same concept.
- Primary reference: `/docs/refactor-audit/04_RESPONSIBILITY_AND_BOUNDARY_AUDIT.md` (`RB-05`), `/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md` (`PR-011`)
- Dependency note: depends on completion-boundary stabilization; avoid before `RF-010` and `RF-011` are complete.
- Parallel Group: `PG-F-RELIABILITY-CANONICAL`
- Can Run With: `RF-029`
- Must Not Overlap With: `RF-006`, `RF-010`, `RF-011`, `RF-020`
- Status: `deferred`

### RF-027 — Shared Transient Feedback Presenter for Toast / Warning UI
- Short objective: unify duplicated toast and warning presentation behavior plus cancellation ownership.
- Why it matters: repeated timing logic is a cross-screen UX consistency and lifecycle risk.
- Primary reference: `/docs/refactor-audit/05_STATE_MANAGEMENT_AUDIT.md` (`ST-02`), `/docs/refactor-audit/08_REUSABLE_COMPONENTS_AND_UI_DUPLICATION_AUDIT.md` (`UI-03`)
- Dependency note: safer after early flow and state ownership stabilization.
- Parallel Group: `PG-F-TRANSIENT-FEEDBACK`
- Can Run With: `RF-028`
- Must Not Overlap With: `RF-014`, `RF-015`, `RF-021`, `RF-029`, `RF-030`
- Status: `deferred`

### RF-028 — Onboarding Placeholder / Pseudo-Domain Cleanup
- Short objective: remove or isolate placeholder AI service and pseudo-domain scaffolding not connected to production behavior.
- Why it matters: lowers conceptual noise but is not on the critical path.
- Primary reference: `/docs/refactor-audit/07_FEATURE_BOUNDARIES_AND_DEPENDENCY_AUDIT.md` (`FD-04`)
- Dependency note: low priority; use as a parallel filler only when paired with a higher-priority ticket that does not touch onboarding.
- Parallel Group: `PG-F-LOW-RISK-CLEANUP`
- Can Run With: `RF-009`, `RF-010`, `RF-016`, `RF-019`, `RF-020`, `RF-021`, `RF-024`, `RF-027`
- Must Not Overlap With: `RF-029`, `RF-030`
- Status: `deferred`

### RF-029 — CreateNonNegotiableView Structural Split
- Short objective: break `CreateNonNegotiableView` into logical UI sections without behavior change.
- Why it matters: it is one of the largest UI files and a likely future duplication source.
- Primary reference: `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`
- Dependency note: defer until safety foundation and Plan/Cockpit critical flows are stabilized.
- Parallel Group: `PG-F-LOW-RISK-UI-A`
- Can Run With: `RF-011`, `RF-014`, `RF-015`, `RF-018`, `RF-019`, `RF-020`, `RF-021`, `RF-022`, `RF-025`, `RF-026`
- Must Not Overlap With: `RF-027`, `RF-028`, `RF-030`
- Status: `future`

### RF-030 — CockpitLogsScreen Secondary Section Split
- Short objective: continue splitting `CockpitLogsScreen` into non-behavioral sections now that shared toolbar/profile concerns are extracted.
- Why it matters: the screen remains over 1000 LOC and still carries structural risk.
- Primary reference: `/docs/refactor-audit/03_FILE_SIZE_AND_COMPLEXITY_AUDIT.md`
- Dependency note: can follow if additional low-risk UI work is needed between higher-risk phases.
- Parallel Group: `PG-F-LOW-RISK-UI-B`
- Can Run With: `RF-014`, `RF-015`, `RF-017`, `RF-018`, `RF-019`, `RF-021`, `RF-022`, `RF-025`
- Must Not Overlap With: `RF-027`, `RF-028`, `RF-029`
- Status: `future`

---

## 6. Planning notes and dependency notes

Planning constraints:
- Do not start `PlanScreen`, `PlanStore`, or `CommitmentSystemStore` decomposition before the existing behavior-lock tests and parity-prep gates are satisfied.
- Do not merge navigation-contract work with persistence or store decomposition in one ticket.
- Do not centralize duplicated completion or reliability logic before parity tests and one-caller migration are complete.
- Completed `RF-001` through `RF-005` validate the workflow and the first safety foundation; they do not remove the remaining flow-ownership risks.

Important sequencing notes:
- The strongest current parallel pair is one of these two options: `RF-006 + RF-007` or `RF-012 + RF-008`, subject to the `project.pbxproj` caveat above.
- `RF-007` and `RF-008` must stay separate because both are project/build-integrity edits.
- `RF-009`, `RF-010`, and `RF-012` all touch navigation or flow ownership and should not be active at the same time.
- `RF-010` and `RF-011` must stay split; one-caller migration first is safer than dual-path migration.
- `RF-018` and `RF-019` deliberately remain separate so `PlanStore` persistence and projection can be reviewed independently.
- `RF-023` remains blocked until startup reset intent is clarified because the audit identifies product and policy uncertainty there.
- Later parallel work should prefer one high-risk architecture ticket plus one unrelated low-risk UI or cleanup ticket, not two hotspot tickets in the same subsystem.
