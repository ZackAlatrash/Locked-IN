# 06 Concurrency, MainActor, Async Audit

## Purpose and scope
This document evaluates actor/thread boundaries and async usage across UI, stores, and persistence paths.
It focuses on what is actually on MainActor today, cancellation gaps, reentrancy hazards, and unsafe ordering patterns.

## Summary
Concurrency style is inconsistent. Large stores are globally `@MainActor`, yet they run synchronous persistence and heavy recomputation paths. UI timing relies on many unstructured delayed tasks.

- Severity: **High**
- Confidence: **High confidence**
- Inventory baseline: `@MainActor 18`, `DispatchQueue.main 16`, `Task { 5}` (`docs/refactor-audit/data/pattern_concurrency_counts.txt`).

## Inventory highlights
| Pattern | Evidence |
|---|---|
| Global actor isolation on major stores | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:9`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:50` |
| UI delayed tasks for transient state | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:469-476`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift:87-93`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1415-1421` |
| Repeated `DispatchQueue.main.asyncAfter` chains | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1516-1523,1537-1550`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:464-491` |
| Async calendar permission flow | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:141-145`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:302-327` |

## Findings

### Finding CC-01: MainActor hosts synchronous persistence and compute-heavy store refresh
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Threading risk**, **Production risk**
- Evidence:
  - Store is `@MainActor`: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:50`.
  - Synchronous save path called from mutations: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:953-960`.
  - Refresh pipeline recomputes multiple projections on main actor: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:188-206,802-944`.
  - Repository does blocking file I/O (`Data(contentsOf:)`, `data.write`) synchronously: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:35,58`.
- Interpretation:
  - UI actor is executing file I/O + large projection builds.
- Future implication:
  - Frame drops/jank risk increases with larger datasets or frequent updates.

### Finding CC-02: Commitment store also performs synchronous persistence on MainActor
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Threading risk**, **Production risk**
- Evidence:
  - `@MainActor` store: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:9`.
  - Persist writes called after most mutations: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:628-635`.
  - Repository I/O is blocking: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:41,64`.
- Interpretation:
  - Domain writes and disk writes share UI actor path.
- Future implication:
  - Latency spikes during frequent completion logging and integrity ticks.

### Finding CC-03: Unstructured task lifecycle with no cancellation handles
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **UX flow risk**
- Evidence:
  - Toast timers in multiple views use detached `Task {}` with sleep and no `Task` handle storage/cancel: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:469-476`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1415-1421`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift:87-93`.
- Interpretation:
  - View disappearance/recreation does not cancel prior delayed effects deterministically.
- Future implication:
  - Stale delayed updates can override newer UI state.

### Finding CC-04: DispatchQueue-based animation sequencing creates ordering hazards
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**, **UX flow risk**
- Evidence:
  - Multi-step animation sequencing with hard-coded delays in `PlanScreen`: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift:1516-1550`.
  - Similar staged delayed transitions in `CockpitLogsScreen`: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift:464-491`.
- Interpretation:
  - Ordering is time-based rather than state-based.
- Future implication:
  - Timing-dependent regressions under slower devices or background/foreground transitions.

### Finding CC-05: Async API usage is narrow; most concurrency is timing hacks
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Architecture risk**
- Evidence:
  - Real async path is mainly calendar permission access (`PlanViewModel` + `AppleCalendarProvider`).
  - Most remaining concurrency usage is delayed UI cleanup and animation timing.
- Interpretation:
  - Async/await is not used as a coherent boundary strategy; it is mostly incidental.
- Future implication:
  - Hard to reason about cancellation and actor guarantees as features scale.

## Areas needing deeper tracing in next pass
1. `PlanStore.refresh` call frequency under rapid `store.system` updates.
2. Interaction between `MainAppView.onChange` triggers and store mutation bursts.
3. UI staleness risk when delayed toast tasks overlap across modal transitions.

## Conclusion
Concurrency risks are primarily architectural: oversized MainActor stores and unstructured delayed UI tasks. Current patterns are functional but fragile under load and lifecycle churn.
