# RF-003 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-003-test-target-baseline-support.md`

## Purpose
Implement the first test-infrastructure slice:
- add a `LockedInTests` unit test target,
- add minimal baseline test support,
- add one deterministic smoke test,
- keep scope out of risky store/flow behavior coverage.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-003-test-target-baseline-support.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md` (Sections 13 and 14)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/decision-log.md` (`AD-002`, `AD-012`)
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`

## Scope
- Add a new unit test target named `LockedInTests`.
- Add baseline test directory/support files.
- Add one deterministic smoke test against a dependency-light app-module type.
- Ensure there is a documented working `xcodebuild` path to run the new target.

## Out of Scope
- Store behavior-lock tests.
- Cross-store completion tests.
- Navigation/overlay tests.
- Persistence lifecycle tests.
- Architectural cleanup in production code beyond what is strictly required for test-target compilation.

## Priority Concerns
1. Keep the slice infrastructure-only.
2. Avoid introducing project-file instability.
3. Make the test command reproducible and documented.

## Required Output
- In-scope project/test infrastructure changes only.
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/handoffs/RF-003-summary.md`

Summary must include:
- files changed,
- target/support files added,
- exact `xcodebuild` list/test command(s) used,
- smoke test result,
- open concerns or environment caveats.

## Notes
- This ticket is the gateway for later behavior-lock testing tickets.
- Do not opportunistically add `PlanStore`, `CommitmentSystemStore`, or flow tests here.
