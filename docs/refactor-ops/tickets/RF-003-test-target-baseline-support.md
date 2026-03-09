# RF-003 — Add LockedIn Test Target and Baseline Test Support

## Why this ticket exists
The refactor cannot safely move into store, flow, or persistence stabilization while the project has no test target and no executable test harness. This ticket creates the minimum testing infrastructure required for later behavior-lock tickets without yet attempting broad coverage.

## Audit evidence
- No meaningful automated tests or test target exist:
  - `/docs/refactor-audit/14_TEST_COVERAGE_AND_SAFETY_AUDIT.md` (`TS-01`..`TS-04`)
  - `docs/refactor-audit/data/project_target_inventory.txt:46-57`
  - `docs/refactor-audit/data/test_files_scan.txt` (empty)
- Priority map explicitly requires test locks first:
  - `/docs/refactor-audit/16_REFACTOR_PRIORITY_MAP.md`
- Executive summary identifies missing tests as critical refactor risk:
  - `/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md` (problem 10)
- Current project state still has only the app target:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn.xcodeproj/project.pbxproj`

## Problem statement
There is no unit test target, no repository test folder structure, and no baseline test support. That means later high-risk tickets have nowhere safe to add behavior-lock tests and every structural change remains under-protected.

## Goal
Create the first `LockedInTests` unit test target and the minimum baseline support needed so later tickets can add real behavior-lock tests with low friction.

## In scope
- Xcode project changes required to add one unit test target:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn.xcodeproj/project.pbxproj`
- New test source root and baseline structure, for example under:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedInTests/`
  - or `/Users/zackalatrash/Desktop/Locked IN/Tests/UnitTests/`
- Minimal baseline test support files needed for deterministic unit tests.
- One smoke test proving:
  - the test target builds,
  - the test bundle runs,
  - the app module can be imported and exercised through a dependency-light, deterministic type.

## Out of scope
- PlanStore, CommitmentSystemStore, or cross-store behavior-lock tests.
- Navigation/overlay tests.
- Persistence lifecycle tests.
- Refactoring production source code for architectural cleanup unless strictly necessary to enable test compilation.
- Any behavior change in the app runtime.
- Broad CI/workflow automation outside what is necessary to run the new test target locally.

## Behavior constraints
- App runtime behavior must remain unchanged.
- Production target membership and runtime ownership boundaries must remain unchanged except for project changes necessary to add the test bundle.
- The smoke test must target a dependency-light pure or near-pure type; it must not become the first behavior-lock test for risky runtime flows.

## Architecture rule being enforced
- `/docs/refactor-ops/architecture-rules.md`
  - Rule 13: Critical logic must be testable.
  - Rule 14: Tests protect behavior.
  - Rule 12: Refactors must be reviewable.
- `/docs/refactor-ops/target-architecture.md`
  - Section 13: Testing expectations by layer.
  - Section 14: Protect behavior first before structural decomposition.
- `/docs/refactor-ops/decision-log.md`
  - `AD-002`: safety-first sequencing.
  - `AD-012`: testing is a gating architecture concern.

## Ownership Rules
- Rules enforced now:
  - `/docs/refactor-ops/ownership-rules.md` `OR-A17` and `OR-A18` indirectly by preparing the required safety net for later orchestration work.
- Transitional exceptions:
  - None expected.
- Ownership movement:
  - Test infrastructure ownership:
    - current owner: absent
    - target owner: dedicated unit test target and test-support files
- QC checks:
  - Ticket stays in test infrastructure only.
  - No hidden architectural cleanup is bundled into the target setup.

## Required implementation changes
1. Add a unit test target named `LockedInTests` to the Xcode project.
2. Add baseline test folder structure and at least the minimal files required for the target to compile and run.
3. Add one deterministic smoke test against a dependency-light type from the app module to prove target execution.
4. Ensure the new target can be listed and built/test-invoked from `xcodebuild`.
5. Do not add behavior-lock coverage for risky runtime flows in this ticket; that work belongs to later tickets.

## Required tests
Decision: **Tests required as part of this ticket.**

Required verification:
1. `xcodebuild -project LockedIn.xcodeproj -list` shows `LockedInTests`.
2. `xcodebuild test` invocation for the new test target succeeds, or if simulator constraints require an adjusted invocation, the Developer must document the exact working command and result.
3. The included smoke test passes.

## Acceptance criteria
- The project has a `LockedInTests` unit test target.
- The repository contains baseline test structure and at least one executable smoke test.
- The smoke test is deterministic and limited to infrastructure validation, not risky feature behavior.
- A documented `xcodebuild` test command exists and succeeds in the implementation environment.
- No unrelated production code or architecture concerns are modified.

## Risks
- Project-file churn or target misconfiguration could create build instability.
- Developer may be tempted to broaden scope into actual store/flow tests before infrastructure is stable.
- Simulator or local test-run environment constraints may complicate verification; the exact working command must be captured.

## QC focus
- Confirm scope is limited to test-target and baseline support setup.
- Confirm no production behavior changes or unrelated architectural edits were bundled in.
- Confirm the smoke test is intentionally minimal and deterministic.
- Confirm a real, reproducible test command exists and succeeded.

## Completion notes required from Developer
Developer must provide:
- files changed
- summary of target and baseline test support added
- exact command(s) used to list/build/run the test target
- smoke test coverage summary
- open concerns or environment limitations
