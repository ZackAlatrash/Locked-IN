# LockedIn Refactor Architecture Decision Log

## Purpose

Record architecture decisions for the refactor program in a stable, update-friendly format.
This log is maintained by Instructor and referenced by ticket, handoff, and QC review documents.

## Update rules

1. Do not rewrite old decisions silently.
2. If a decision changes, add a new decision that supersedes the old one.
3. Every decision must include:
- stable ID,
- date,
- status,
- rationale (with audit grounding),
- consequences.
4. Status values:
- `Accepted` (active baseline),
- `Provisional` (accepted with known uncertainty),
- `Deferred` (intentionally postponed),
- `Superseded` (replaced by later decision).

---

## AD-001 — Behavior preservation is default refactor contract

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Audit shows high regression risk across navigation, persistence, and global state coupling (`01`, `05`, `13`, `15`).
  - Workflow rules require conservative interpretation and behavior-safe increments.
- Consequences:
  - Tickets must state behavior constraints explicitly.
  - Any intended behavior change requires explicit ticket language, rationale, and verification steps.

## AD-002 — Refactor sequencing is safety-first (tests/stabilization before deep decomposition)

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - No effective test safety net (`14`, `PR-006`).
  - Priority map requires behavior locks before structural edits (`16`).
- Consequences:
  - High-risk areas require preparatory tickets when coverage is weak.
  - Large structural tickets without safety prep are non-compliant.

## AD-003 — Transitional architecture keeps current top-level folders; no big-bang directory rewrite

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Current structure is mixed and drifted, but broad folder rewrite would amplify risk (`02`, `03`, `15`).
- Consequences:
  - Immediate work focuses on boundary ownership, not mass moves.
  - `CoreUI -> DesignSystem` is incremental and ticket-driven, not immediate.

## AD-004 — Dependency direction target is View -> ViewModel -> UseCase/Coordinator -> Repository protocol -> Repository implementation

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Responsibility collapse exists in views/stores today (`04`, `07`).
  - Needed to reduce ad hoc cross-feature mutation chains.
- Consequences:
  - New/refactored code must follow direction even if neighboring legacy code does not yet.
  - Tickets should introduce narrow boundaries before replacing legacy paths.

## AD-005 — Shared global stores are transitional; feature code should migrate to narrow interfaces

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - `PlanStore` and `CommitmentSystemStore` are high-coupling dependency hubs (`01`, `05`, `07`, `15`).
- Consequences:
  - Do not add new direct full-store dependencies unless explicitly justified.
  - Prefer feature-facing read/write contracts and coordinator/use-case boundaries.

## AD-006 — Navigation ownership split is resolved by policy: shell owns global overlays, features own local stacks

- Date: 2026-03-08
- Status: Provisional
- Rationale:
  - Current shell/feature overlap causes modal and intent fragility (`13`, `PR-012`).
  - Exact intent lifecycle semantics remain partially uncertain (`18` UQ-06).
- Consequences:
  - Tickets may stabilize deterministic consume/replace semantics incrementally.
  - Product/UX clarifications may be required before finalizing edge-case behavior.

## AD-007 — Completion orchestration must converge to one shared boundary

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Completion side-effect chain duplicated in Cockpit and DailyCheckIn (`04`, `05`, `07`, `15` PR-010).
- Consequences:
  - No new duplicate completion chain logic.
  - Migration should move one caller at a time behind a shared orchestration contract.

## AD-008 — Persistence writes must be isolated from presentation and migrate away from blocking MainActor paths

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Sync file I/O on `@MainActor` stores is a production/threading risk (`06`, `12`, `15` PR-007).
- Consequences:
  - New persistence behavior in views/VMs is disallowed.
  - Async boundary improvements should be incremental and test-protected.

## AD-009 — Startup destructive reset behavior is treated as high-risk legacy until explicitly resolved

- Date: 2026-03-08
- Status: Provisional
- Rationale:
  - Production startup includes destructive one-time resets (`12`, `15` PR-009).
  - Intent is uncertain (`18` UQ-01).
- Consequences:
  - Do not expand this pattern.
  - Any change requires explicit ticketed behavior policy and verification plan.

## AD-010 — Shared UI extraction priority is behavior-carrying duplication, not cosmetic dedup

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Harmful duplication centers on modal presenters, top bars, and transient toast timing behavior (`08`).
- Consequences:
  - UI extraction tickets should target behavior-consistency gains first.
  - Broad styling redesign is deferred.

## AD-011 — Concurrency policy: cancellable delayed tasks and explicit actor boundaries

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Unstructured delayed tasks and time-based sequencing are causing lifecycle fragility (`06`, `15` PR-013).
- Consequences:
  - New delayed UI work must define cancellation ownership.
  - Concurrency cleanups must avoid behavior drift; test protection required.

## AD-012 — Testing is a gating architecture concern, not optional follow-up

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Audit confirms critical missing tests for stores, orchestration, navigation arbitration, and persistence lifecycle (`14`, `16`).
- Consequences:
  - Every ticket must explicitly choose: test-first, test-in-ticket, or deferred-with-risk.
  - “Testing unspecified” is invalid for Instructor tickets.

## AD-013 — Ticket sizing rule: one central architectural goal per ticket

- Date: 2026-03-08
- Status: Accepted
- Rationale:
  - Critical hotspots are tightly coupled; mega tickets would be unreviewable and regression-prone (`03`, `15`, `16`).
- Consequences:
  - No combined `PlanScreen + PlanStore + CommitmentSystemStore` restructuring in one ticket.
  - QC should flag scope creep as a failure condition.

## AD-014 — Open product/intent uncertainties remain explicit until resolved

- Date: 2026-03-08
- Status: Provisional
- Rationale:
  - Several behavior contracts remain uncertain (reliability source of truth, popup precedence timing, intent lifecycle, migration policy) (`18`).
- Consequences:
  - Tickets in these domains must include assumptions section.
  - If assumptions are risky, create preparatory clarification/stabilization ticket first.

---

## Supersession index

- None yet.

---

## Next-update template

Use this format for future entries:

```md
## AD-0XX — <Decision title>
- Date: YYYY-MM-DD
- Status: Accepted | Provisional | Deferred | Superseded
- Supersedes: AD-0YY (optional)
- Rationale:
  - ...
- Consequences:
  - ...
```
