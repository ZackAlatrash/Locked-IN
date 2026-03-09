# 10_NAMING_AND_CODE_CLARITY_AUDIT

## Purpose and Scope
Identify naming inconsistencies, terminology drift, and clarity issues that increase cognitive load and maintenance risk.

## Summary
Naming is partially descriptive, but domain terminology is inconsistent and responsibility names are overloaded.

## Findings
### Finding 1: Domain term drift between `NonNegotiable` and `Protocol`
- Type: Architecture risk
- Severity: High
- Confidence: High confidence
- Evidence:
  - Domain entity/model names use `NonNegotiable` (`LockedIn/Domain/Models/NonNegotiable.swift`).
  - UI and flow labels heavily use `Protocol` (`LockedIn/Features/Plan/Views/PlanScreen.swift:413`, `:493`, `:2021`; `LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift:7-10`).
- Why this is risky now:
  - Same concept expressed with different names causes interpretation mistakes and duplicate abstractions.
- Pass B follow-up:
  - Define canonical glossary and map aliases explicitly.

### Finding 2: Overloaded role suffixes (`Store`, `Engine`, `Controller`) hide responsibility boundaries
- Type: Architecture risk
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - `CommitmentSystemStore`, `PlanStore`, `DevOptionsController`, `CommitmentSystemEngine`, `PlanRegulatorEngine`, `NonNegotiableEngine` all carry broad behavior.
  - Evidence paths: `LockedIn/Application/PlanStore.swift`, `LockedIn/Application/CommitmentSystemStore.swift`, `LockedIn/Application/DevOptionsController.swift`, `LockedIn/Domain/Engines/*.swift`.
- Why this is risky now:
  - Names suggest clean roles, but implementations are multi-role (state + orchestration + persistence + policy mediation).
- Pass B follow-up:
  - Validate actual responsibility matrix per type.

### Finding 3: App entry naming is inconsistent (`Locked_INApp` vs `LockedIn`)
- Type: Code smell
- Severity: Low
- Confidence: High confidence
- Evidence:
  - App entry struct is `Locked_INApp` in `LockedIn/App/Locked_INApp.swift:11`, while project/target naming is `LockedIn`.
- Why this is risky now:
  - Inconsistent naming weakens discoverability and increases grep friction.
- Pass B follow-up:
  - Confirm intended naming convention for app-level symbols.

### Finding 4: Placeholder and simulation naming coexist in production source tree
- Type: Production risk
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - `PlaceholderAIService` in `LockedIn/Core/Services/AIServiceProtocol.swift:66`.
  - Multiple `*Simulation.swift` files in Domain/Application and included in source build phase (`docs/refactor-audit/data/pbx_simulation_in_sources.txt`).
- Why this is risky now:
  - Naming suggests temporary/dev-only behavior living in shipping target context.
- Pass B follow-up:
  - Validate runtime reachability and packaging intent.

## Confusing Terminology Signals
- `Protocol` often means user commitment unit, not Swift protocol.
- `System stable` and `Recovery` states are represented in multiple places with different phrasing (`STABLE`, `NORMAL`, `RECOVERY`).
- `Plan` terms include queue, allocations, regulator draft, and structure status with overlapping semantics.

## Glossary of Recurring Domain Terms (Current Usage)
| Term | Where seen | Observed meaning |
|---|---|---|
| NonNegotiable | Domain models/engines/stores | Core commitment entity |
| Protocol | Plan/Cockpit/Recovery UI | User-facing label for same entity class |
| Recovery | Domain state + UI mode | Constraint mode with stricter behavior |
| Regulator | Plan models + VM + UI sheet | Auto-planning suggestion engine |
| Queue | Plan screen/store | Unscheduled protocol work inventory |
| Integrity | Daily/check-in/store labels | Compliance/violation state framing |

## Areas with Obvious Naming Drift
1. `NonNegotiable` vs `Protocol` (same conceptual object).
2. Mode/state labels (`stable/normal/recovery`) across different files.
3. Temporary/placeholder naming in files that are target-members.

## Conclusion
Naming quality is not uniformly poor, but terminology drift is strong enough to create real architecture and maintenance friction. Domain glossary normalization is required before high-risk refactor work.
