# RF-008 — Developer Handoff

## Source Ticket
Reference:
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-008-remove-simulation-files-from-app-target-membership.md`

## Purpose
Remove simulation files from the production app target without changing runtime behavior.

## Required Reading
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/tickets/RF-008-remove-simulation-files-from-app-target-membership.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/01_EXECUTIVE_SUMMARY.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/15_PRODUCTION_READINESS_RISK_REGISTER.md`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-audit/data/pbx_simulation_in_sources.txt`
- `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/architecture-rules.md`

## Scope
- Remove the audit-identified simulation files from `LockedIn` app target membership.
- Keep project metadata coherent.
- Verify the app still builds.

## Out of Scope
- Deleting or refactoring simulation source.
- Stale project-file reference repair (`RF-007`).
- Any production runtime code change.
- Any scheme/build-setting redesign.

## Priority Concerns
1. Keep this to project wiring only.
2. Do not touch unrelated project metadata.
3. Preserve production build behavior.

## Required Output
- Completion summary:
  - `/Users/zackalatrash/Desktop/Locked IN/docs/refactor-ops/completed/RF-008-summary.md`

Summary must include:
- files changed,
- simulation files removed from app target membership,
- exact build command used,
- exact build result,
- any unexpected dependency discovered.

## Required verification command
- `xcodebuild -project 'LockedIn.xcodeproj' -scheme 'LockedIn' -destination 'generic/platform=iOS Simulator' build`
  - Required result: `BUILD SUCCEEDED`
