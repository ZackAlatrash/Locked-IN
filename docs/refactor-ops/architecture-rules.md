# LockedIn Refactor Architecture Rules

## Purpose
This document defines the architectural rules that must guide the refactor of the LockedIn codebase.

All agents in the refactor workflow must follow these rules:
- Instructor
- Developer
- Quality Control

These rules prevent architectural drift during refactoring and ensure long-term maintainability.

---

# Core Principles

## 1. Preserve Behavior
Refactoring must **not change existing behavior** unless a ticket explicitly states otherwise.

If behavior might change, the ticket must:
- explicitly state it
- explain why
- include tests or verification steps

---

## 2. Incremental Refactoring
Refactoring must happen in **small, controlled increments**.

A single ticket must not:
- rewrite an entire feature
- refactor multiple unrelated systems
- combine navigation, persistence, and state restructuring

Prefer:
- one architectural improvement per ticket
- vertical slices over large horizontal rewrites

---

## 3. Evidence-Based Decisions
All refactor tickets must reference findings from:

`/docs/refactor-audit/`

Planning must not rely on intuition alone.

---

# Structural Architecture Rules

## 4. Views Must Be Thin
SwiftUI Views should only contain:
- layout
- presentation
- simple UI state
- event forwarding

Views must **not contain**:
- business rules
- persistence logic
- complex orchestration
- heavy data transformations

---

## 5. Business Logic Must Have Clear Ownership
Business rules must not be scattered across:
- views
- random helpers
- unrelated services

Business logic should live in:
- view models
- domain services
- clearly defined rule engines

---

## 6. Persistence Must Be Isolated
Views and UI layers must not directly perform persistence operations.

Persistence should be handled through:
- repositories
- storage services
- dedicated persistence layers

---

## 7. State Ownership Must Be Clear
State must have a single clear owner.

Avoid:
- duplicated state
- state being mutated from multiple unrelated components
- hidden shared state

State should flow in predictable directions.

---

## 8. File Size Discipline
Extremely large files reduce maintainability.

Targets (guidelines, not strict limits):

Preferred:
- < 300 lines

Warning:
- 300–600 lines

High risk:
- 600+ lines

Critical:
- 1000+ lines

Large files should be split along **logical boundaries**, not arbitrarily.

---

## 9. Avoid “God Objects”
No single object should control:
- UI
- persistence
- navigation
- business rules
- state orchestration

Responsibilities must be separated.

---

# Refactor Workflow Rules

## 10. Tickets Define Scope
The ticket in:

`/docs/refactor-ops/tickets/`

is the **source of truth** for scope.

Agents must not expand scope based on chat instructions if a ticket exists.

---

## 11. No Hidden Refactors
Developer must not:
- rename unrelated symbols
- refactor neighboring systems
- delete code without explanation

Every change must relate to the ticket.

---

## 12. Refactors Must Be Reviewable
Each refactor must be small enough that:

Quality Control can meaningfully review:
- architecture improvement
- behavior preservation
- structural quality

---

# Testing Rules

## 13. Critical Logic Must Be Testable
When business rules are moved or centralized, tests should be added where appropriate.

If tests are missing, the ticket must explicitly acknowledge the risk.

---

## 14. Tests Protect Behavior
Tests should confirm that refactors do not change behavior.

---

# Documentation Rules

## 15. Every Refactor Leaves a Trail
Each ticket must produce:

- ticket file
- developer summary
- QC review
- ledger update

These live under:

`/docs/refactor-ops/`

---

# Safety Rule

If any agent is unsure about:
- behavior impact
- ownership boundaries
- refactor scope

The agent must choose the **most conservative interpretation** and request clarification.

---

# Long-Term Goal

The refactor should produce a codebase that is:

- modular
- understandable
- maintainable
- testable
- resistant to architectural drift