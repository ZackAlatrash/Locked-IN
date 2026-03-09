# 18 Open Questions and Uncertainties

## Purpose and scope
This document records uncertainties that remain after Pass B and require human/product confirmation or deeper behavior tracing before refactor.

## Summary
Most structural risks are confirmed. Remaining uncertainty is concentrated in product-rule intent and persistence lifecycle decisions that are not explicit in code comments/contracts.

- Overall confidence on open items: **Medium confidence**

## Open questions

### UQ-01: Are startup destructive resets intentional for production builds?
- Severity: **Critical**
- Confidence: **High confidence (fact), low confidence (intent)**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-95` runs one-time reset logic and clears stores.
- Uncertainty:
  - Intent of these resets in release runtime is unclear.
- Why this matters:
  - Determines whether behavior is a known rollout tactic or an accidental production data-loss risk.

### UQ-02: Canonical source of truth for reliability score
- Severity: **High**
- Confidence: **High confidence (duplicate formulas), medium confidence (intended divergence)**
- Evidence:
  - Cockpit formula: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:162-189`.
  - DailyCheckIn formula: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:434-456`.
- Uncertainty:
  - Are these intentionally different contexts or unintended drift?

### UQ-03: Expected precedence when recovery popup and daily check-in are both eligible
- Severity: **High**
- Confidence: **Medium confidence**
- Evidence:
  - Shell currently suppresses daily check-in while recovery is pending (`MainAppView.swift:73-75,268-274`).
- Uncertainty:
  - Product rule for deferred check-in timing after recovery resolution is implicit, not explicitly specified.

### UQ-04: Persistence migration strategy for existing users
- Severity: **High**
- Confidence: **Medium confidence**
- Evidence:
  - Repositories decode current models directly without explicit schema migration (`JSONFile*Repository.swift`).
- Uncertainty:
  - Is backward compatibility guaranteed elsewhere, or not addressed yet?

### UQ-05: Release policy for simulation files currently included in app Sources
- Severity: **Critical**
- Confidence: **High confidence (inclusion), low confidence (intent)**
- Evidence:
  - `docs/refactor-audit/data/pbx_simulation_in_sources.txt:1-12`.
- Uncertainty:
  - Are these expected to ship in release, or accidentally left in target membership?

### UQ-06: Intended lifecycle guarantees for router pending intents
- Severity: **Medium**
- Confidence: **Medium confidence**
- Evidence:
  - Intent set in one feature, consumed in another (`AppRouter.swift`, `PlanScreen.swift:174-181,1476-1491`).
- Uncertainty:
  - Is at-most-once intent consumption required? Current implementation implies but does not enforce transaction semantics.

### UQ-07: Recovery pause-selection policy details
- Severity: **Medium**
- Confidence: **Medium confidence**
- Evidence:
  - Requires selection only when active+recovery count > 1 (`CommitmentSystemStore.swift:676-683`).
- Uncertainty:
  - Is this threshold product-approved and immutable, or temporary logic?

### UQ-08: Desired logging policy in production runtime
- Severity: **Medium**
- Confidence: **High confidence (prints exist), low confidence (policy intent)**
- Evidence:
  - Active `print` in store load/save and plan VM diagnostics (`CommitmentSystemStore.swift:61,64,631,633`; `PlanViewModel.swift:278-281`).
- Uncertainty:
  - Should logs be user-invisible structured telemetry, or are console prints accepted for now?

## Areas requiring deeper cross-file reasoning before implementation
1. Exact ordering guarantees for completion side effects across both completion entry points.
2. Interaction of delayed tasks with navigation transitions and scene phase changes.
3. Whether plan allocation status transitions (`paused` -> `active/skippedDueToRecovery`) match product expectations after recovery exit.

## Conclusion
The remaining unknowns are mostly product/intent decisions, not missing code facts. These decisions should be resolved before Phase 2 implementation to avoid refactoring into the wrong behavioral contract.
