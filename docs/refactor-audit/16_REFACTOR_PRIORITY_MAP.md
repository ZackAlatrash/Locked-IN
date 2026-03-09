# 16 Refactor Priority Map

## Purpose and scope
This document defines a dependency-ordered refactor sequence for Phase 2+ based on Pass B risk and coupling evidence.
It is sequencing guidance only; no implementation in this pass.

## Summary
The system cannot be safely refactored in one pass. Sequence must start with test locks on mutation-heavy behavior, then isolate orchestration boundaries, then decompose god files.

- Overall severity: **High**
- Overall confidence: **High confidence**
- Estimated complexity: **High (multi-sprint)**

## Evidence
- Critical hotspot files: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift`, `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift`.
- Test vacuum: `docs/refactor-audit/data/project_target_inventory.txt:46-57`, empty `test_*` scans.
- Cross-store duplication: completion chain in Cockpit and DailyCheckIn (`CockpitView.swift:353-360`, `DailyCheckInViewModel.swift:196-204`).

## Interpretation
Risk is dependency-ordered: testing and flow stabilization must happen before structural decomposition, otherwise every change has undefined blast radius.

## Future implication
Skipping sequence will likely produce regressions that are hard to localize because ownership is currently collapsed across layers.

## Ranked priorities
| Rank | Priority | Severity | Confidence | Why now | Dependencies |
|---|---|---|---|---|---|
| 1 | Establish behavior-lock tests for stores and cross-store completion chain | Critical | High confidence | No refactor safety net exists | None |
| 2 | Stabilize navigation/overlay ownership semantics | Critical | High confidence | Shell + feature modal conflicts can break core flows | Priority 1 tests |
| 3 | Consolidate completion orchestration boundary used by Cockpit and DailyCheckIn | High | High confidence | Duplicated side-effect chain is active divergence risk | Priorities 1-2 |
| 4 | Isolate persistence writes from MainActor-heavy paths | High | High confidence | Performance + reliability risk from synchronous I/O on UI actor | Priority 1 |
| 5 | Decompose `PlanScreen` by flow slices (board, sheets, editor, toasts) | High | High confidence | Largest UI blast radius and maintainability hotspot | Priorities 1-3 |
| 6 | Decompose `PlanStore` into explicit mutation/projection responsibilities | High | High confidence | Central god object blocks all features | Priorities 1,3,4 |
| 7 | Decompose `CommitmentSystemStore` recovery/log/projection concerns | High | High confidence | Critical domain + persistence coupling | Priorities 1,3,4 |
| 8 | Remove/guard simulation and stale project metadata from release target | High | High confidence | Release integrity risk | Parallel with 1-4 |
| 9 | Normalize duplicated rule computations (reliability, weekly remaining, messaging) | Medium | High confidence | UX inconsistency and drift | Priorities 3,5,6 |
| 10 | Clean naming/legacy placeholder debt | Low | Medium confidence | Improves readability after architecture hardening | After structural priorities |

## Minimum safety work before structural edits
1. Test `PlanStore` placement validation, move/remove, draft apply, reconcile-after-completion.
2. Test `CommitmentSystemStore` recovery transitions and daily integrity tick.
3. Integration-test completion from Cockpit and DailyCheckIn and assert equal side effects.
4. Flow test for shell arbitration: recovery popup suppresses daily-checkin popup.
5. Persistence tests for startup reset key behavior and repository failure paths.

## Recommended vertical-slice sequence (Phase 2+)
1. **Slice A: Completion path**
   - Introduce one orchestration boundary for completion + reconciliation + integrity tick.
   - Migrate Cockpit and DailyCheckIn to same boundary.
2. **Slice B: Navigation ownership**
   - Formalize intent lifecycle and overlay ownership contract.
3. **Slice C: Plan flow decomposition**
   - Break `PlanScreen` into behavior slices while keeping behavior unchanged.
4. **Slice D: Store decomposition**
   - Split `PlanStore` and `CommitmentSystemStore` responsibilities behind tested interfaces.
5. **Slice E: Persistence hardening**
   - Add schema versioning/migration and structured persistence error policy.

## Anti-patterns to avoid
- Do not refactor `PlanScreen`, `PlanStore`, and `CommitmentSystemStore` simultaneously.
- Do not change routing semantics while replacing store contracts.
- Do not centralize duplicated rules before behavior-lock tests exist.
- Do not execute giant-bang architectural rewrite.

## Conclusion
Phase 2 should start with safety and ownership stabilization, then proceed slice-by-slice through the highest blast-radius paths. Any giant-pass approach is high-risk for production regressions.
