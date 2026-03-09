# 12 Data Persistence and Storage Audit

## Purpose and scope
This document audits where and how persistence/storage is accessed, how it is coupled to presentation, and which data integrity/relaunch risks are visible from code.

## Summary
Persistence is simple JSON-file based and works, but ownership is scattered: app startup, stores, views (`@AppStorage`), and dev tooling all mutate durable state. There is no migration/versioning strategy and limited failure handling.

- Severity: **High**
- Confidence: **High confidence**

## Persistence/storage access inventory
| Storage path | Access points | Evidence |
|---|---|---|
| `commitment_system.json` in Documents | `JSONFileCommitmentSystemRepository` via `CommitmentSystemStore` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:30-79`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:628-635` |
| `plan_allocations.json` in Documents | `JSONFilePlanAllocationRepository` via `PlanStore` | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:25-73`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:953-960` |
| UserDefaults / `@AppStorage` prompt and UI flags | App shell, profile, app root, dev tools, cockpit/logs/plan animation flags | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:47-53`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:24-26,83-95`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:35-37,310-329` |
| EventKit calendar data | `AppleCalendarProvider` (read-only event fetch) | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:290-351` |

## Findings

### DP-01: Persistence writes are synchronous and executed from MainActor stores
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Threading risk**, **Production risk**
- Evidence:
  - `PlanStore` `@MainActor` save path: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:50,953-960`.
  - `CommitmentSystemStore` `@MainActor` persist path: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:9,628-635`.
  - Repository blocking I/O: `Data(contentsOf:)` and `data.write`: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:41,64`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:35,58`.
- Interpretation:
  - Disk I/O competes with UI actor.
- Future implication:
  - Latency/jank under frequent writes.

### DP-02: Startup includes destructive one-time reset logic in production app root
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Production risk**, **Data risk**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-95` clears onboarding + store data when flags are absent.
- Interpretation:
  - Data lifecycle behavior is tied to hard-coded one-time keys and app startup path.
- Future implication:
  - Unintended data resets if keys are changed/cleared between builds.

### DP-03: Storage coupling to presentation (`@AppStorage`) is spread across unrelated screens
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Architecture risk**, **Bug risk**
- Evidence:
  - Prompt policy keys read/write in shell: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:48-53,276-327`.
  - Prompt time edited in profile screen: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift:5-6,136-156`.
  - Dev options mutate same keys: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/DevOptionsController.swift:226-229,294-297`.
- Interpretation:
  - Durable behavioral state is controlled from multiple presentation surfaces.
- Future implication:
  - Hard-to-debug prompt behavior drift across sessions.

### DP-04: No explicit schema versioning/migration for JSON persistence
- Severity: **High**
- Confidence: **Medium confidence**
- Classification: **Data risk**, **Maintainability risk**
- Evidence:
  - Repositories decode current models directly with no explicit version field or migration layer.
  - Paths: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:47`; `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:41`.
- Interpretation:
  - Backward compatibility depends on Codable defaults and model evolution discipline.
- Future implication:
  - Model changes can break old persisted data or force silent data loss.

### DP-05: `PlanCalendarEvent.id` is generated as random UUID per fetch
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**, **State restoration risk**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:341-343` assigns `id: UUID()` during mapping.
- Interpretation:
  - Same calendar event receives different IDs each refresh.
- Future implication:
  - Unstable identity for diffing/state restoration and potential UI flicker or stale selection behavior.

### DP-06: Persistence failure handling is mostly warning/print with limited recovery
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Production risk**
- Evidence:
  - `PlanStore` sets warning but continues refresh (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:953-960`).
  - `CommitmentSystemStore` logs save failures via `print` only (`/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift:631-633`).
- Interpretation:
  - Persistence errors are observable but not strongly recoverable.
- Future implication:
  - Potential silent persistence inconsistency after write failures.

## Relaunch/state restoration danger signals
1. Startup reset keys in app root can alter persisted state on launch (`Locked_INApp.swift:83-95`).
2. Daily check-in behavior depends on mutable defaults keys shared across features (`MainAppView`, `ProfilePlaceholderView`, `DevOptionsController`).
3. Simulation files are included in app target (`docs/refactor-audit/data/pbx_simulation_in_sources.txt:1-12`), increasing release contamination risk.

## Unknowns requiring deeper tracing
- Whether stale/corrupt JSON recovery path is user-visible and safe (no dedicated corruption quarantine path seen).
- Whether calendar-event identity instability causes observable UI state loss in plan board interactions.

## Conclusion
Persistence works through straightforward file storage, but coupling and lifecycle ownership are fragile. The highest-risk issue is destructive startup/reset behavior combined with distributed presentation-level writes to durable state.
