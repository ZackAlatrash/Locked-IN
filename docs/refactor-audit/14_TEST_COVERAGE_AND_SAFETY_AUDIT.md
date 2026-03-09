# 14 Test Coverage and Safety Audit

## Purpose and scope
This document evaluates whether the current codebase has enough automated protection to support safe refactoring.
It focuses on critical flows and their current test coverage status.

## Summary
The safety net is critically weak. There is no meaningful test target/test suite coverage for runtime-critical flows.

- Severity: **Critical**
- Confidence: **High confidence**

## Test target inventory
| Item | Observation | Evidence |
|---|---|---|
| App targets | `LockedIn` only | `docs/refactor-audit/data/project_target_inventory.txt:46-57` |
| Test directories | None in repo source tree (excluding derived data) | `find`/scan output; `docs/refactor-audit/data/test_directories_scan.txt` (empty) |
| Test files | None detected | `docs/refactor-audit/data/test_files_scan.txt` (empty) |

## Findings

### TS-01: No automated protection for core store behavior
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Testing risk**, **Production risk**
- Evidence:
  - Core behavior centralized in `PlanStore` and `CommitmentSystemStore` (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:51-1227`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:10-847`).
  - No corresponding tests found.
- Interpretation:
  - Most business-critical logic has zero regression guardrails.
- Future implication:
  - Any refactor can break completion, recovery, and plan consistency silently.

### TS-02: No tests for cross-store orchestration chains
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Testing risk**, **Bug risk**
- Evidence:
  - Completion chain duplicated in feature code (`CockpitView` and `DailyCheckInViewModel`), both untested.
  - Paths: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:353-360`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:196-204`.
- Interpretation:
  - Highest-risk multi-step behavior has no assertions.
- Future implication:
  - Rule divergence and side-effect ordering regressions will escape easily.

### TS-03: Navigation/overlay flow behavior is unprotected
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Testing risk**, **UX flow risk**
- Evidence:
  - Complex shell orchestration in `MainAppView` with multiple trigger sources (`scenePhase`, tab changes, simulated time, store updates): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:142-180`.
- Interpretation:
  - No automated confirmation of modal arbitration rules.
- Future implication:
  - High chance of regressions in popup timing/dismissal when changing state flow.

### TS-04: Persistence lifecycle and relaunch behavior are untested
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Testing risk**, **Data risk**
- Evidence:
  - Startup reset behavior in app root (`Locked_INApp.swift:83-95`).
  - JSON persistence read/write paths in repositories (`JSONFile*Repository.swift`).
- Interpretation:
  - Destructive and persistent state transitions have no protection.
- Future implication:
  - Data loss regressions can ship unnoticed.

## Critical missing tests before any refactor
1. Store-level behavioral tests for `PlanStore` placement/validation/reconciliation.
2. Store-level behavioral tests for `CommitmentSystemStore` recovery transitions and daily integrity tick.
3. Integration tests for completion flows from Cockpit and DailyCheckIn, asserting identical side effects.
4. Navigation-flow tests for shell overlay arbitration (`recovery` vs `daily check-in`).
5. Persistence tests for load/save failure handling and startup reset key behavior.

## Why missing tests are especially dangerous here
- Logic is duplicated across features, so regressions can be asymmetric.
- Stores are high-complexity god objects with mixed responsibilities.
- UI-layer orchestration creates hidden side effects that are difficult to validate manually.

## Conclusion
This codebase is not refactor-safe today. Minimum prerequisite work is targeted behavior-lock testing around stores, cross-store chains, and shell navigation orchestration.
