# 15 Production Readiness Risk Register

## Purpose and scope
This register captures concrete production risks identified in Pass B with evidence-backed impact analysis.
Mitigations are future-phase guidance only (no refactor in this pass).

## Summary
Risk concentration is highest around shared stores, flow orchestration, missing tests, and release-integrity signals in project configuration.

- Overall severity: **Critical**
- Overall confidence: **High confidence**

## Evidence
- Large-file and pattern baseline: `docs/refactor-audit/data/swift_loc_top_60.txt`, `docs/refactor-audit/data/pattern_*` outputs.
- Project integrity issues: `docs/refactor-audit/data/pbx_simulation_in_sources.txt`, `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt`.
- Core code hotspots: `PlanStore`, `CommitmentSystemStore`, `PlanScreen`, `MainAppView`.

## Interpretation
The codebase has concentrated architectural and operational risk where global stores, navigation ownership, and persistence lifecycle intersect.

## Future implication
Without staged mitigation, the probability of shipping regression during refactor is high even for localized changes.

## Risk register
| Risk ID | Title | Description | Affected files/features | Likelihood | Impact | Severity | Confidence | Category | Why it matters in production | Recommended mitigation (future phase) |
|---|---|---|---|---|---|---|---|---|---|---|
| PR-001 | God view in core planning flow | `PlanScreen` mixes UI, orchestration, sheets, drag/drop, undo/toast, router intent consumption | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/Views/PlanScreen.swift` | High | High | Critical | High confidence | architecture / maintainability | Small edits can break unrelated plan behavior | Stabilize with behavior-lock tests, then split by flow responsibility |
| PR-002 | God store for plan state | `PlanStore` owns validation, queue, projections, persistence, warnings, reconciliation | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift` | High | High | Critical | High confidence | architecture / data | Single failure path can affect scheduling + persistence + UI feedback | Introduce store contract tests and extract mutation/use-case boundaries incrementally |
| PR-003 | God store for commitment domain | `CommitmentSystemStore` combines mutation, recovery transitions, logs, persistence | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/CommitmentSystemStore.swift` | High | High | Critical | High confidence | architecture / data | Recovery and integrity behavior can regress silently | Add deterministic scenario tests for recovery and daily tick before decomposition |
| PR-004 | Simulation files in app Sources | Simulation entrypoints are compiled into app target | `docs/refactor-audit/data/pbx_simulation_in_sources.txt:1-12` | Medium | High | Critical | High confidence | release integrity | Increases release contamination and accidental invocation risk | Move simulations out of app target or gate by build config |
| PR-005 | Missing pbx file reference | `IdentityWarningViewModel.swift` referenced by project but missing on disk | `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt:1` | Medium | Medium | High | High confidence | build integrity | Project graph drift can break builds unpredictably | Repair project references and add integrity check in CI |
| PR-006 | No test target/suite | No meaningful automated tests for core behavior | `docs/refactor-audit/data/project_target_inventory.txt:46-57`; empty test scans | High | High | Critical | High confidence | testing | Refactor risk is uncontrolled | Create test target and prioritize high-blast behavior tests |
| PR-007 | MainActor blocking I/O | Stores on MainActor perform synchronous repository I/O | `PlanStore.swift:953-960`; `CommitmentSystemStore.swift:628-635`; JSON repos | High | Medium | High | High confidence | threading / performance | UI jank under frequent writes | Move persistence off main actor with explicit async boundaries |
| PR-008 | Distributed prompt state writes | Daily check-in prompt keys mutated from shell, profile, and dev tools | `MainAppView.swift`, `ProfilePlaceholderView.swift`, `DevOptionsController.swift` | High | Medium | High | High confidence | data / UX flow | Prompt behavior can feel inconsistent across relaunches | Centralize prompt-state writes behind one boundary |
| PR-009 | Startup destructive resets in app root | One-time reset flags trigger store wipes on startup | `/Users/zackalatrash/Desktop/Locked IN/LockedIn/App/Locked_INApp.swift:83-95` | Medium | High | Critical | High confidence | data / production | Data loss risk if flags are absent/reset | Remove destructive startup behavior from production path |
| PR-010 | Rule duplication across features | Completion messaging and orchestration duplicated in Cockpit and DailyCheckIn | `CockpitView.swift`; `DailyCheckInViewModel.swift` | High | Medium | High | High confidence | architecture / bug risk | Behavior divergence by entry point | Consolidate shared completion workflow in one domain boundary |
| PR-011 | Reliability score divergence | Different formulas for same metric | `CockpitViewModel.swift:162-189`; `DailyCheckInViewModel.swift:434-456` | High | Medium | High | High confidence | UX consistency | Users can see contradictory system status | Define one canonical reliability computation source |
| PR-012 | Manual intent-consume navigation model | Router intents are manually consumed and timing-sensitive | `AppRouter.swift`; `PlanScreen.swift:174-181,1476-1491` | Medium | Medium | High | High confidence | UX flow | Lost/duplicate deep-link behavior under fast transitions | Add deterministic intent lifecycle model with tests |
| PR-013 | Unstructured delayed UI tasks | Multiple delayed timers with `Task.sleep`/`DispatchQueue.main.asyncAfter` | `PlanScreen.swift`, `CockpitView.swift`, `DailyCheckInFlowView.swift` | Medium | Medium | Medium | High confidence | threading / UX | Stale delayed updates can overwrite current state | Use cancellable task ownership per view lifecycle |
| PR-014 | No explicit persistence migration strategy | JSON decode uses current models directly without versioned migrations | `JSONFileCommitmentSystemRepository.swift`; `JSONFilePlanAllocationRepository.swift` | Medium | High | High | Medium confidence | data | Model evolution may break persisted user data | Add schema versioning + migration layer |
| PR-015 | Runtime `print` in production stores | Active `print` in store load/save paths and plan VM diagnostics | `CommitmentSystemStore.swift:61,64,631,633`; `PlanViewModel.swift:278-281` | High | Low | Medium | High confidence | observability / security hygiene | Unstructured logs are noisy and inconsistent | Replace with structured logger policy |

## Conclusion
Current production readiness risk is dominated by architecture and testing deficits. The risk register indicates a stabilization-first Phase 2 is mandatory before structural refactor work.
