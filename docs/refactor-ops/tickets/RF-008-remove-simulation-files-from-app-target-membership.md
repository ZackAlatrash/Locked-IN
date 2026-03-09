# RF-008 — Remove Simulation Files from App Target Membership

## Why this ticket exists
The audit identified production project contamination: simulation entrypoints are compiled into the app target. This is a release-integrity risk that can be corrected without changing runtime behavior.

This is a small structural cleanup ticket intended to reduce project configuration risk only.

## Audit evidence
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md`
  - Problem 8: production project includes simulation files in app Sources
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
  - `PR-004` Simulation files in app Sources
- Supporting evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/data/pbx_simulation_in_sources.txt`

## Problem statement
Simulation-only files are still wired into the production app target. That increases release contamination risk and weakens confidence that production builds contain only production code paths.

## Goal
Remove simulation files from `LockedIn` app target membership while preserving current production behavior and keeping the scope limited to project configuration.

## In scope
- `LockedIn.xcodeproj/project.pbxproj` target membership changes required to remove simulation files from the app target.
- Any minimal Xcode project group/reference cleanup required to keep project metadata coherent after target-membership removal.
- Verification that the production app target still builds after the cleanup.

## Out of scope
- Deleting simulation source files.
- Refactoring or renaming simulation code.
- Changing runtime production code paths.
- Build-setting redesign, scheme redesign, or broader project file cleanup unrelated to simulation target membership.
- Repairing unrelated stale project references (`RF-007` owns that work).

## Behavior constraints
- Production behavior must remain unchanged.
- This ticket changes project wiring only; it must not change feature logic, store logic, navigation, or persistence behavior.
- If a simulation file is unexpectedly required for production compilation, document that dependency and stop short of broader refactor work.

## Architecture and ownership rules being enforced
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`
  - Rule 1: preserve behavior
  - Rule 2: incremental refactoring
  - Rule 11: no hidden refactors
  - Rule 12: refactors must be reviewable
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/ownership-rules.md`
  - `OR-A14` keep release-integrity cleanup separate from navigation/store work
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/target-architecture.md`
  - Sections 4 and 14: incremental migration without broad restructure

## Ownership Rules
- Rules enforced now:
  - `OR-A14`
- Transitional exceptions:
  - none expected
- Ownership movement:
  - Current owner: app target incorrectly owns simulation compilation
  - Target owner: simulation files are excluded from production app target membership
- QC checks:
  - only project wiring changed,
  - no runtime files changed unless strictly required for project coherence,
  - no unrelated project metadata cleanup bundled in.

## Required implementation changes
1. Remove the simulation files identified by the audit from the `LockedIn` app target membership.
2. Keep project metadata internally consistent after the removal.
3. Do not mix in stale-reference cleanup or other project-file maintenance beyond what this ticket requires.

## Required verification
Developer must document:
1. Which simulation files were removed from app target membership.
2. A passing production build command, for example:
   - `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'generic/platform=iOS Simulator' build`
3. Confirmation that no production source files were modified for behavior reasons.

## Acceptance criteria
- The simulation files called out in `/docs/refactor-audit/data/pbx_simulation_in_sources.txt` are no longer members of the `LockedIn` app target.
- The `LockedIn` scheme still builds successfully after the project-file change.
- No production runtime behavior changes are introduced.
- Scope remains limited to simulation target membership and directly necessary project metadata updates.

## Risks
- `project.pbxproj` edits are easy to widen accidentally; scope discipline matters.
- Some simulation code may have implicit project wiring assumptions that surface only after target cleanup.

## QC focus
- Confirm the targeted simulation files are removed from production target membership.
- Confirm the project still builds.
- Confirm unrelated pbx cleanup was not bundled in.
- Confirm no runtime behavior changes were introduced.

## Completion notes required from Developer
Developer must provide:
- files changed,
- exact simulation files removed from app target membership,
- exact build command used and result,
- any unexpected dependency discovered during target cleanup.
