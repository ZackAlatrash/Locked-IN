# Testing Audit

## Current Test Surface (Observed)
- Test targets from project list: `LockedIn`, `LockedInTests` (no UI test target observed).
- Test suite shape: **8 test classes**, **31 `test*` methods**, **10 Swift test files**.
- Coverage focus: repository behavior-lock tests + parity tests + calculator unit tests.

## Findings

### LI-008 - High-risk test categories are missing
- Severity: **High**
- Type: **Testing, Production Risk**
- Why it matters:
  - There is no UI/integration harness for startup routing, recovery popup arbitration, or daily check-in auto-prompt behavior.
  - Regressions in top-level flow logic can pass unit tests while breaking user-critical paths.
- Affected files/types:
  - App shell and flow orchestration (`LockedInAppRoot`, `MainAppView`, routing/prompt policies).
- Evidence:
  - `xcodebuild -list` reports only `LockedIn` and `LockedInTests` targets.
  - Core orchestration logic lives in:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:59-99`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:149-338`
  - No UI test suite exists in repository.
- Recommended fix direction:
  - Add UI/integration tests for startup, recovery entry, daily-checkin prompting, and tab routing behaviors.
- Confidence: **High**

### LI-055 - No explicit tests protect the startup destructive reset branch
- Severity: **Critical**
- Type: **Testing, Correctness**
- Why it matters:
  - Critical data-affecting startup logic has no direct regression tests.
- Affected files/types:
  - `LockedInAppRoot` startup path.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-89`.
  - No test references found for `didRunFreshStartReset20260303` or startup reset flow in `LockedInTests`.
- Recommended fix direction:
  - Add app-startup tests validating migration/reset behavior against existing persisted data and key absence/presence states.
- Confidence: **High**

### LI-056 - Persistence failure paths are not tested with production repositories
- Severity: **High**
- Type: **Testing, Durability**
- Why it matters:
  - The suite primarily uses recording/in-memory repositories, so real decode/corruption behavior is unverified.
- Affected files/types:
  - Repository-backed services and JSON repositories.
- Evidence:
  - Recording repos in fixtures:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/RepositoryCommitmentServiceTestFixtures.swift:4-24`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/RepositoryPlanServiceTestFixtures.swift:4-24`
  - No tests found exercising `JSONFileCommitmentSystemRepository`/`JSONFilePlanAllocationRepository` corruption recovery.
- Recommended fix direction:
  - Add file-backed repository tests: malformed JSON, partial writes, permission errors, and restart consistency.
- Confidence: **High**

### LI-052 - Behavior-lock tests are strong locally but over-indexed versus integration confidence
- Severity: **Medium**
- Type: **Testing Strategy**
- Why it matters:
  - Behavior-lock coverage is useful for migration parity, but does not ensure end-to-end app correctness.
- Affected files/types:
  - Plan and commitment behavior-lock suites.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/PlanStore/RepositoryPlanServiceBehaviorLockTests.swift`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/CommitmentSystemStore/RepositoryCommitmentServiceBehaviorLockTests.swift`
- Recommended fix direction:
  - Keep behavior-lock tests, but rebalance with integration tests around app shell and persistence boundaries.
- Confidence: **High**

### LI-053 - Static retainers in tests can hide lifecycle issues and test pollution
- Severity: **Medium**
- Type: **Testing Reliability**
- Why it matters:
  - Global static arrays retain stores/routers/view models across tests, potentially masking deallocation/lifecycle defects.
- Affected files/types:
  - Test fixture retainers and parity retainers.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/RepositoryCommitmentServiceTestFixtures.swift:126-131`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/RepositoryPlanServiceTestFixtures.swift:118-123`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/Parity/CrossFeatureCompletionParityTests.swift:159-181`
- Recommended fix direction:
  - Replace global retainers with scoped ownership patterns and explicit teardown assertions.
- Confidence: **High**

### LI-054 - Smoke coverage is minimal and does not validate system wiring
- Severity: **Medium**
- Type: **Testing Coverage**
- Why it matters:
  - Current smoke test only validates a date rule computation and gives little confidence in app assembly.
- Affected files/types:
  - Smoke suite.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/Smoke/LockedInSmokeTests.swift:4-12`.
- Recommended fix direction:
  - Expand smoke suite to include service construction, repository load/save roundtrip, and app-shell route smoke checks.
- Confidence: **High**

### LI-057 - No explicit concurrency/threading tests for actor assumptions
- Severity: **Medium**
- Type: **Testing, Concurrency**
- Why it matters:
  - Main-thread assumptions are broad but unverified under concurrent access patterns.
- Affected files/types:
  - Repository services and view models with async/timed behavior.
- Evidence:
  - Main-actor service and async timer usage in:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryPlanService.swift:50-51,1213-1219`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Data/RepositoryCommitmentService.swift:9-10,625-632`
  - No dedicated concurrency stress tests in `LockedInTests`.
- Recommended fix direction:
  - Add concurrency-focused tests for mutation ordering, timer cancellation, and actor-isolated behavior.
- Confidence: **Medium**

### LI-058 - Temporal boundary tests are narrow (timezone and locale transitions mostly untested)
- Severity: **Medium**
- Type: **Testing, Correctness**
- Why it matters:
  - Date/week logic heavily depends on `.current` timezone/calendar semantics in production.
  - Existing tests mainly use fixed UTC fixtures and do not validate timezone-change behavior.
- Affected files/types:
  - `DateRules` consumers across planning/compliance/check-in flows.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Shared/Domain/DateRules.swift:13-17`.
  - Test fixtures pin UTC:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/TestCalendarSupport.swift`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/TestSupport/RepositoryPlanServiceTestFixtures.swift:27`
- Recommended fix direction:
  - Add timezone-shift and DST boundary tests for week/day evaluations and policy gating.
- Confidence: **Medium**

### LI-059 - AppShell recovery/daily-checkin arbitration has no direct regression suite
- Severity: **High**
- Type: **Testing, Architectural Risk**
- Why it matters:
  - Core user flow arbitration is implemented in one view with many triggers; untested orchestration is a high regression vector.
- Affected files/types:
  - `MainAppView`.
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/AppShell/Views/MainAppView.swift:149-187,262-338`.
  - No dedicated tests for `evaluateRecoveryEntryPresentation` / `evaluateDailyCheckInAutoPresentation`.
- Recommended fix direction:
  - Add integration tests around these evaluators with explicit AppStorage state permutations.
- Confidence: **High**

## Confidence Assessment
Current suite provides **moderate confidence** for migrated service behavior parity, but **low confidence** for production durability and full-flow UX correctness. The highest leverage test investment is integration coverage around startup/migration/persistence and app-shell orchestration.
