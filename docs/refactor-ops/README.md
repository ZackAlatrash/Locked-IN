# Refactor Ops Workflow

## Purpose
This folder defines the multi-agent refactor workflow for LockedIn.

The workflow is designed to keep refactoring:
- incremental
- evidence-based
- reviewable
- behavior-safe

It separates planning, implementation, and review into distinct agents.

---

## Agents
The workflow uses three primary agents:

- Instructor
- Developer
- Quality Control

Agent instructions live in:
- `/docs/refactor-ops/agents/instructor.md`
- `/docs/refactor-ops/agents/developer.md`
- `/docs/refactor-ops/agents/quality-control.md`

---

## Source of truth
Planning must be grounded in:
- `/docs/refactor-audit/`

Operational workflow artifacts live in:
- `/docs/refactor-ops/`

---

## Folder structure

### `/docs/refactor-ops/agents/`
Agent operating instructions.

### `/docs/refactor-ops/inbox/`
Human notes or steering input.
Examples:
- `audit-context.md`
- `next-ticket-request.md`

### `/docs/refactor-ops/tickets/`
Instructor-created refactor tickets.
These define the official scope of a refactor slice.

### `/docs/refactor-ops/handoffs/`
Agent-to-agent working briefs.
Examples:
- Developer handoff
- QC handoff

### `/docs/refactor-ops/reviews/`
QC review documents.
Examples:
- ticket scope review
- implementation review

### `/docs/refactor-ops/completed/`
Completion summaries for finished tickets.

### `/docs/refactor-ops/refactor-ledger.md`
Running history of:
- completed tickets
- deferred issues
- recurring architecture decisions
- workflow notes

### `/docs/refactor-ops/architecture-rules.md`
Stable architecture rules that all agents must follow.

---

## Workflow sequence

### Step 1 — Instructor plans
The Instructor reads the audit files and creates:
- a ticket in `/docs/refactor-ops/tickets/`
- a developer handoff in `/docs/refactor-ops/handoffs/`
- a QC handoff in `/docs/refactor-ops/handoffs/`

Optional:
- QC may review ticket scope before implementation

### Step 2 — Developer implements
The Developer reads:
- the ticket
- the developer handoff
- architecture rules

The Developer then performs only the scoped implementation.

After implementation, the Developer creates:
- a completion/handoff summary in `/docs/refactor-ops/handoffs/` or `/completed/`

This summary must include:
- files changed
- summary of changes
- tests added/updated
- open concerns

### Step 3 — QC reviews
QC reads:
- the original ticket
- the QC handoff
- the Developer’s completion summary
- the changed files/diff

QC writes review output to:
- `/docs/refactor-ops/reviews/`

QC must give:
- Pass / Conditional Pass / Fail
- what improved
- problems found
- scope creep found
- required fixes

### Step 4 — Instructor closes or requeues
If the ticket passes, the Instructor updates:
- `/docs/refactor-ops/refactor-ledger.md`
- `/docs/refactor-ops/completed/`

If the ticket fails or is conditional, the Instructor creates the next corrective step.

---

## Communication rules

### Rule 1
Tickets define scope.  
No agent may treat vague chat intent as the source of truth if a ticket exists.

### Rule 2
Developer does not choose new scope.

### Rule 3
QC does not silently rewrite the task; QC reviews against the ticket.

### Rule 4
Instructor does not directly modify source code.

### Rule 5
Every meaningful refactor slice must leave a file trail:
- ticket
- handoff(s)
- review
- ledger update

---

## Naming conventions

### Tickets
- `RF-001-short-title.md`

### Developer handoffs
- `RF-001-developer-handoff.md`

### QC handoffs
- `RF-001-qc-handoff.md`

### Scope reviews
- `RF-001-ticket-scope-review.md`

### Implementation reviews
- `RF-001-implementation-review.md`

### Completion summaries
- `RF-001-summary.md`

---

## Scope discipline rules
A ticket should generally:
- have one main architecture goal
- stay within one feature/subfeature unless shared code is the explicit target
- avoid broad renaming
- avoid mixing navigation, persistence, and state restructuring in one step
- be small enough for meaningful QC review

---

## Default operating principle
When uncertain, agents should choose the more conservative interpretation and preserve current behavior.