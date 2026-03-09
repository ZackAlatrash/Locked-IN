# 09 Business Logic Duplication Audit

## Purpose and scope
This document identifies repeated business rules, calculations, validations, and state-transition logic across files.
It distinguishes fact (duplicate implementations) from inference (potential divergence risk).

## Summary
The same domain concepts are implemented repeatedly across features, especially around completion handling, reliability scoring, and weekly remaining logic. This is an active divergence risk, not theoretical debt.

- Severity: **High**
- Confidence: **High confidence**

## Duplication clusters

### BL-01: Completion orchestration chain duplicated across features
- Severity: **Critical**
- Confidence: **High confidence**
- Classification: **Bug risk**, **Architecture risk**
- Evidence:
  - Cockpit flow: `recordCompletionDetailed -> reconcileAfterCompletion -> runDailyIntegrityTick` in `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:353-360`.
  - DailyCheckIn flow: same chain in `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:196-204`.
- Interpretation:
  - Two independent implementations orchestrate identical side effects.
- Future implication:
  - Any rule update in one path can silently desync behavior in the other.

### BL-02: Completion/reconciliation user messaging duplicated
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Code smell**, **Bug risk**
- Evidence:
  - “Logged as EXTRA” messaging in both files:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:363-366`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:206-209`
  - “Tomorrow's slot was removed” wording in both files:
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/Views/CockpitView.swift:486-494`
    - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:215-218`
- Interpretation:
  - Rule explanation copy is duplicated and hand-maintained.
- Future implication:
  - User-facing policy guidance can diverge by entry point.

### BL-03: Reliability score is implemented differently per feature
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Bug risk**, **Architecture risk**
- Evidence:
  - Cockpit scoring formula: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:162-189`.
  - DailyCheckIn scoring formula: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:434-456`.
- Interpretation:
  - Same semantic metric has two formulas and different penalties.
- Future implication:
  - Screen-to-screen reliability discrepancy is expected, not accidental.

### BL-04: Weekly remaining calculations repeated in multiple layers
- Severity: **High**
- Confidence: **High confidence**
- Classification: **Code smell**, **Bug risk**
- Evidence:
  - Plan queue remaining: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Application/PlanStore.swift:771-777`.
  - DailyCheckIn remainingWeek: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:71-77`.
  - Cockpit session remaining text: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:291-334`.
- Interpretation:
  - Same weekly-cap concept is rederived in at least three places.
- Future implication:
  - Edge-case fix in one location will not automatically propagate.

### BL-05: `defaultDurationMinutes(for:)` duplicated
- Severity: **Medium**
- Confidence: **High confidence**
- Classification: **Code smell**
- Evidence:
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Plan/ViewModels/PlanViewModel.swift:422-427`
  - `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:458-464`
- Interpretation:
  - Shared default domain rule implemented twice.
- Future implication:
  - Silent rule drift likely when defaults change.

### BL-06: Mode-label and recovery labeling logic repeated
- Severity: **Medium**
- Confidence: **Medium confidence**
- Classification: **Code smell**, **Architecture risk**
- Evidence:
  - DailyCheckIn mode label (`NORMAL/RECOVERY`): `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift:427-432`.
  - Cockpit mode label logic: `/Users/zackalatrash/Desktop/Locked IN/LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift:49-54`.
- Interpretation:
  - Shared system-state display semantics are duplicated.
- Future implication:
  - Inconsistent labels under transition states.

## Rule divergence already visible
- Reliability formula mismatch is already explicit.
- Completion messaging strings are parallel but not centralized.
- Weekly remaining logic includes slightly different assumptions across Plan, DailyCheckIn, and Cockpit contexts.

## Pass B follow-up candidates (verification queue)
1. Compare outputs for same sample system state across Cockpit and DailyCheckIn reliability functions.
2. Compare “remaining this week” values for daily/session mode across Plan queue vs DailyCheckIn protocol list.
3. Verify identical completion side effects from Cockpit path and DailyCheckIn path under recovery mode.

## Conclusion
Business rules are duplicated in multiple features and layers. This creates immediate consistency risk and guarantees high-cost maintenance unless behavior is centralized in a later phase.
