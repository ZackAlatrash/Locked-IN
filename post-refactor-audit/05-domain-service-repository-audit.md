# Domain, Service & Repository Audit

## Findings

### LI-002 - Persistence failure behavior can silently degrade to empty state or unsaved mutations
- Severity: **Critical**
- Type: **Correctness, Production, Durability**
- Why it matters:
  - Load failure in services falls back to empty in-memory models without user-visible escalation.
  - Save failures are mostly swallowed (`try?`) or logged with `print`.
  - This can manifest as data disappearance after restart with no actionable signal.
- Affected files/types:
  - `RepositoryCommitmentService`, `RepositoryPlanService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:56-62,625-632`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:96-100,422,553,757,952`.
- Recommended fix direction:
  - Introduce explicit load/save result handling policy: user-safe recovery, error surfacing, and telemetry.
  - Avoid silent mutation success when durability fails.
- Confidence: **High**

### LI-006 - Recovery completion requirement rules are duplicated across engine and service layers
- Severity: **High**
- Type: **Correctness, Maintainability**
- Why it matters:
  - Same rule family exists in two implementations; future edits can diverge behavior.
  - Recovery correctness is user-critical.
- Affected files/types:
  - `CommitmentSystemEngine`, `RepositoryCommitmentService`.
- Evidence:
  - Engine implementation:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Engines/CommitmentSystemEngine.swift:273-329`.
  - Service implementation:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:751-825`.
- Recommended fix direction:
  - Consolidate rule evaluation into one domain authority and consume from other layers.
- Confidence: **High**

### LI-024 - Services remain broad "store-like" aggregations rather than bounded domain services
- Severity: **High**
- Type: **Architectural, Maintainability**
- Why it matters:
  - Service classes mix commands, reads, UI projections, and persistence triggers.
  - Hard to reason about invariants and testing scope.
- Affected files/types:
  - `RepositoryPlanService`, `RepositoryCommitmentService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:52-71,666-1221`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:384-845`.
- Recommended fix direction:
  - Separate command/write services from query/projection services.
  - Keep domain policy and data persistence orchestration in distinct components.
- Confidence: **High**

### LI-044 - Cross-feature completion flows duplicate orchestration logic
- Severity: **High**
- Type: **Maintainability, Correctness Drift Risk**
- Why it matters:
  - Cockpit and DailyCheckIn each implement completion + reconciliation + toast messaging behavior.
  - Drift here creates inconsistent user outcomes.
- Affected files/types:
  - `CockpitViewModel`, `DailyCheckInViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:66-98,100-122`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:192-225`.
- Recommended fix direction:
  - Introduce shared completion use-case service returning a unified outcome model for both features.
- Confidence: **High**

### LI-050 - Policy API includes context parameter that is currently ignored
- Severity: **Medium**
- Type: **Domain Clarity, Maintainability**
- Why it matters:
  - API signals behavior branching (`manual` vs `regulator`) but implementation discards it.
  - Creates misleading contract and likely future bugs.
- Affected files/types:
  - `CommitmentPolicyEngine.canPlaceAllocation`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Policy/CommitmentPolicyEngine.swift:126-157` (`_ = context`).
- Recommended fix direction:
  - Either implement context-specific policy logic or remove the unused parameter to simplify contract.
- Confidence: **High**

### LI-049 - Core capacity policy is hard-coded in model property
- Severity: **Medium**
- Type: **Domain Maintainability**
- Why it matters:
  - Capacity rule (`3` normal, `2` when recovering) is embedded directly in data model, limiting policy evolution.
- Affected files/types:
  - `CommitmentSystem`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Domain/Models/CommitmentSystem.swift:68-70`.
- Recommended fix direction:
  - Move capacity policy to configurable domain policy layer with explicit tests.
- Confidence: **High**

### LI-047 - Repository durability policy lacks corruption quarantine/recovery workflow
- Severity: **High**
- Type: **Production, Correctness**
- Why it matters:
  - JSON repositories throw decode/load errors, but services treat them as reset opportunities.
  - No backup/restore/quarantine path exists for corrupted payloads.
- Affected files/types:
  - JSON repositories + repository-backed services.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift:46-50`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift:40-44`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:56-62`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:96-100`.
- Recommended fix direction:
  - Add durable recovery strategy: backup snapshots, decode fallback migration path, and surfaced recovery state.
- Confidence: **High**

### LI-051 - `RepositoryPlanService` behavior depends on prior `refresh` context (`lastSystem`) in non-obvious ways
- Severity: **Medium**
- Type: **Maintainability, Correctness**
- Why it matters:
  - Some operations are no-ops or warnings when context was not established via `refresh`.
  - This hidden precondition is not explicit in API.
- Affected files/types:
  - `RepositoryPlanService`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:232-235` (descriptor guard fails).
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:956-959` (`guard let lastSystem else { return }`).
- Recommended fix direction:
  - Make context dependency explicit (constructor-injected state source or required `bootstrap` call with failure contract).
- Confidence: **Medium-High**

### LI-016 - Calendar event identity is regenerated each fetch, reducing reconciliation stability
- Severity: **Medium**
- Type: **Correctness, Maintainability**
- Why it matters:
  - Event IDs are `UUID()` per mapping, so same event appears as new identity every refresh.
  - Can destabilize diffing/reconciliation logic in planning projections.
- Affected files/types:
  - `AppleCalendarProvider`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Models/PlanModels.swift:341-349` (`id: UUID()`).
- Recommended fix direction:
  - Derive stable IDs from EventKit identifiers + time bounds.
- Confidence: **Medium**

### LI-019 - User-facing completion feedback strings are duplicated across features
- Severity: **Medium**
- Type: **Maintainability**
- Why it matters:
  - Messaging policy is encoded in multiple places with near-identical formatting branches.
- Affected files/types:
  - `CockpitViewModel`, `DailyCheckInViewModel`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:100-122`.
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:215-223`.
- Recommended fix direction:
  - Centralize completion feedback formatting into a shared formatter/use-case output mapper.
- Confidence: **High**

## Domain/Service/Repository Verdict
Domain core logic is stronger than pre-refactor, but service boundaries are still broad and partially legacy-shaped. The major production blocker is not domain correctness itself; it is durability semantics and duplicated rule ownership across layers.
