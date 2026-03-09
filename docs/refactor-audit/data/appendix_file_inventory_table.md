| Path | Likely Feature | Likely Type/Category | Approx Responsibility | File Size Note | Audit Note |
|---|---|---|---|---|---|
| `LockedIn/App/Locked_INApp.swift` | App | App Entry | App bootstrap and root dependency wiring | Small/medium (111 LOC) | No size hotspot by LOC |
| `LockedIn/Application/AppClock.swift` | Application | Other | Mixed/unclear | Small/medium (28 LOC) | No size hotspot by LOC |
| `LockedIn/Application/CommitmentSystemStore.swift` | Application | Other | Mixed/unclear | Very large (847 LOC) | High split pressure |
| `LockedIn/Application/DailyCheckInPolicy.swift` | Application | Other | Mixed/unclear | Small/medium (80 LOC) | No size hotspot by LOC |
| `LockedIn/Application/DevOptionsController.swift` | Application | Other | Mixed/unclear | Large (330 LOC) | Multi-responsibility risk |
| `LockedIn/Application/DevRuntimeState.swift` | Application | Other | Mixed/unclear | Small/medium (21 LOC) | No size hotspot by LOC |
| `LockedIn/Application/DevSeedScenario.swift` | Application | Other | Mixed/unclear | Small/medium (36 LOC) | No size hotspot by LOC |
| `LockedIn/Application/PlanCompletionReconciliationSimulation.swift` | Application | Other | Mixed/unclear | Small/medium (92 LOC) | No size hotspot by LOC |
| `LockedIn/Application/PlanStore.swift` | Application | Other | Mixed/unclear | Extreme ("1227 LOC") | God-file candidate |
| `LockedIn/Core/Persistence/CommitmentSystemRepository.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (6 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Persistence/InMemoryCommitmentSystemRepository.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (17 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Persistence/JSONFileCommitmentSystemRepository.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (93 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Persistence/JSONFilePlanAllocationRepository.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (87 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Persistence/PlanAllocationRepository.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (22 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Persistence/RepositorySimulation.swift` | Core | Repository/Persistence | Data load/save and storage boundary | Small/medium (46 LOC) | No size hotspot by LOC |
| `LockedIn/Core/Services/AIServiceProtocol.swift` | Core | Service | External capability/service abstraction | Small/medium (84 LOC) | No size hotspot by LOC |
| `LockedIn/CoreUI/Components/FitnessLiquidGlassNavStyle.swift` | CoreUI | Component | Reusable UI subview | Medium-large (246 LOC) | Monitor for drift |
| `LockedIn/CoreUI/Components/GlassCard.swift` | CoreUI | Component | Reusable UI subview | Small/medium (90 LOC) | No size hotspot by LOC |
| `LockedIn/CoreUI/Components/LiquidGlassNavBar.swift` | CoreUI | Component | Reusable UI subview | Medium-large (200 LOC) | Monitor for drift |
| `LockedIn/CoreUI/Components/NonNegotiableCard.swift` | CoreUI | Component | Reusable UI subview | Medium-large (237 LOC) | Monitor for drift |
| `LockedIn/CoreUI/Components/PrimaryButton.swift` | CoreUI | Component | Reusable UI subview | Small/medium (93 LOC) | No size hotspot by LOC |
| `LockedIn/CoreUI/Components/ProgressIndicator.swift` | CoreUI | Component | Reusable UI subview | Small/medium (90 LOC) | No size hotspot by LOC |
| `LockedIn/CoreUI/Theme/Theme.swift` | CoreUI | Other | Mixed/unclear | Medium-large (183 LOC) | Monitor for drift |
| `LockedIn/CoreUI/Utilities/Haptics.swift` | CoreUI | Utility | Cross-cutting helper behavior | Small/medium (49 LOC) | No size hotspot by LOC |
| `LockedIn/CoreUI/Utilities/MotionRuntime.swift` | CoreUI | Utility | Cross-cutting helper behavior | Small/medium (17 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Engines/CommitmentSystemEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Large (390 LOC) | Multi-responsibility risk |
| `LockedIn/Domain/Engines/CommitmentSystemSimulation.swift` | Domain | Other | Mixed/unclear | Medium-large (180 LOC) | Monitor for drift |
| `LockedIn/Domain/Engines/NonNegotiableEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Large (338 LOC) | Multi-responsibility risk |
| `LockedIn/Domain/Engines/NonNegotiableEngineSimulation.swift` | Domain | Other | Mixed/unclear | Medium-large (263 LOC) | Monitor for drift |
| `LockedIn/Domain/Engines/OnboardingEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Small/medium (52 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Engines/OnboardingFlow.swift` | Domain | Other | Mixed/unclear | Small/medium (81 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Engines/PlanRegulatorEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Medium-large (290 LOC) | Monitor for drift |
| `LockedIn/Domain/Engines/PlanRegulatorSimulation.swift` | Domain | Other | Mixed/unclear | Small/medium (68 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Engines/StreakEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Small/medium (36 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/CommitmentSystem.swift` | Domain | Model | Feature/domain data structures | Small/medium (71 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/CompletionRecord.swift` | Domain | Model | Feature/domain data structures | Small/medium (31 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/LockConfiguration.swift` | Domain | Model | Feature/domain data structures | Small/medium (13 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/NonNegotiable.swift` | Domain | Model | Feature/domain data structures | Small/medium (14 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/NonNegotiableDefinition.swift` | Domain | Model | Feature/domain data structures | Medium-large (159 LOC) | Monitor for drift |
| `LockedIn/Domain/Models/NonNegotiableMode.swift` | Domain | Model | Feature/domain data structures | Small/medium (6 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/NonNegotiableState.swift` | Domain | Model | Feature/domain data structures | Small/medium (10 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/OnboardingData.swift` | Domain | Model | Feature/domain data structures | Small/medium (49 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/OnboardingStep.swift` | Domain | Model | Feature/domain data structures | Small/medium (21 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/PlanRegulation.swift` | Domain | Model | Feature/domain data structures | Small/medium (139 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/Violation.swift` | Domain | Model | Feature/domain data structures | Small/medium (13 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Models/Window.swift` | Domain | Model | Feature/domain data structures | Small/medium (23 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Policy/CommitmentPolicyEngine.swift` | Domain | Domain Engine | Domain rules and state transitions | Medium-large (212 LOC) | Monitor for drift |
| `LockedIn/Domain/Policy/CommitmentPolicyEngineSimulation.swift` | Domain | Policy | Policy decisions and restriction reasons | Small/medium (108 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Policy/PolicyDecision.swift` | Domain | Policy | Policy decisions and restriction reasons | Small/medium (14 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Policy/PolicyReason.swift` | Domain | Policy | Policy decisions and restriction reasons | Medium-large (182 LOC) | Monitor for drift |
| `LockedIn/Domain/Policy/ProtocolPatch.swift` | Domain | Policy | Policy decisions and restriction reasons | Small/medium (27 LOC) | No size hotspot by LOC |
| `LockedIn/Domain/Utils/DateRules.swift` | Domain | Other | Mixed/unclear | Small/medium (65 LOC) | No size hotspot by LOC |
| `LockedIn/Features/AppShell/Models/AppRouter.swift` | AppShell | Model | Feature/domain data structures | Small/medium (46 LOC) | No size hotspot by LOC |
| `LockedIn/Features/AppShell/Views/MainAppView.swift` | AppShell | View | UI rendering and user interaction composition | Large (332 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Cockpit/Components/CockpitKpiCard.swift` | Cockpit | Component | Reusable UI subview | Small/medium (53 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Cockpit/Components/CockpitNonNegotiableCard.swift` | Cockpit | Component | Reusable UI subview | Medium-large (203 LOC) | Monitor for drift |
| `LockedIn/Features/Cockpit/Models/CockpitNavigation.swift` | Cockpit | Model | Feature/domain data structures | Small/medium (16 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Cockpit/Models/CockpitUIModel.swift` | Cockpit | Model | Feature/domain data structures | Small/medium (134 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Cockpit/ViewModels/CockpitViewModel.swift` | Cockpit | ViewModel | Presentation state and feature orchestration | Large (404 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Cockpit/Views/CapacityDetailView.swift` | Cockpit | View | UI rendering and user interaction composition | Medium-large (167 LOC) | Monitor for drift |
| `LockedIn/Features/Cockpit/Views/CockpitLogsScreen.swift` | Cockpit | View | UI rendering and user interaction composition | Extreme ("1013 LOC") | God-file candidate |
| `LockedIn/Features/Cockpit/Views/CockpitModernView.swift` | Cockpit | View | UI rendering and user interaction composition | Very large (672 LOC) | High split pressure |
| `LockedIn/Features/Cockpit/Views/CockpitView.swift` | Cockpit | View | UI rendering and user interaction composition | Very large (766 LOC) | High split pressure |
| `LockedIn/Features/Cockpit/Views/FitnessLiquidGlassNavDemoView.swift` | Cockpit | View | UI rendering and user interaction composition | Small/medium (53 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Cockpit/Views/LiquidGlassNavDemos.swift` | Cockpit | Other | Mixed/unclear | Medium-large (206 LOC) | Monitor for drift |
| `LockedIn/Features/Cockpit/Views/ProfilePlaceholderView.swift` | Cockpit | View | UI rendering and user interaction composition | Medium-large (213 LOC) | Monitor for drift |
| `LockedIn/Features/Cockpit/Views/StreakDetailView.swift` | Cockpit | View | UI rendering and user interaction composition | Small/medium (123 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Cockpit/Views/WeeklyActivityDetailView.swift` | Cockpit | View | UI rendering and user interaction composition | Small/medium (104 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/Components/DailyCheckInCard.swift` | DailyCheckIn | Component | Reusable UI subview | Small/medium (37 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/Components/DailyCheckInCloseDayView.swift` | DailyCheckIn | View | UI rendering and user interaction composition | Small/medium (62 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/Components/DailyCheckInProtocolRow.swift` | DailyCheckIn | Component | Reusable UI subview | Small/medium (96 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/Components/DailyCheckInResolutionSheet.swift` | DailyCheckIn | View | UI rendering and user interaction composition | Small/medium (119 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/Models/DailyCheckInModels.swift` | DailyCheckIn | Model | Feature/domain data structures | Small/medium (51 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DailyCheckIn/ViewModels/DailyCheckInViewModel.swift` | DailyCheckIn | ViewModel | Presentation state and feature orchestration | Large (487 LOC) | Multi-responsibility risk |
| `LockedIn/Features/DailyCheckIn/Views/DailyCheckInFlowView.swift` | DailyCheckIn | View | UI rendering and user interaction composition | Large (343 LOC) | Multi-responsibility risk |
| `LockedIn/Features/DevOptions/Components/DevOptionsSectionCard.swift` | DevOptions | Component | Reusable UI subview | Small/medium (63 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DevOptions/Components/DevSeedScenarioRow.swift` | DevOptions | Component | Reusable UI subview | Small/medium (41 LOC) | No size hotspot by LOC |
| `LockedIn/Features/DevOptions/Views/DevOptionsView.swift` | DevOptions | View | UI rendering and user interaction composition | Large (399 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Onboarding/Flow/OnboardingCoordinator.swift` | Onboarding | Flow Coordinator | Flow sequencing and routing logic | Small/medium (133 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/Models/OnboardingPresentationConfig.swift` | Onboarding | Model | Feature/domain data structures | Small/medium (93 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/SubFeatures/AIRegulator/Views/AIRegulatorContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Large (339 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Onboarding/SubFeatures/CommitmentAgreement/ViewModels/CommitmentAgreementViewModel.swift` | Onboarding | ViewModel | Presentation state and feature orchestration | Small/medium (39 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/SubFeatures/CommitmentAgreement/Views/CommitmentAgreementContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (295 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/SubFeatures/CoreDifferentiation/Views/CoreDifferentiationContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Large (379 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Onboarding/SubFeatures/FailureLoop/Views/FailureLoopContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (249 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/SubFeatures/IdentityWarning/Views/IdentityWarningContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (224 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/ViewModels/CreateNonNegotiableViewModel.swift` | Onboarding | ViewModel | Presentation state and feature orchestration | Medium-large (288 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (212 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/CreateNonNegotiableView.swift` | Onboarding | View | UI rendering and user interaction composition | Extreme ("1366 LOC") | God-file candidate |
| `LockedIn/Features/Onboarding/SubFeatures/NonNegotiables/Views/NonNegotiablesContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Small/medium (106 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/SubFeatures/Paywall/Views/PaywallContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Large (402 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Onboarding/SubFeatures/UserHistory/ViewModels/UserHistoryViewModel.swift` | Onboarding | ViewModel | Presentation state and feature orchestration | Small/medium (31 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/SubFeatures/UserHistory/Views/UserHistoryContentView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (212 LOC) | Monitor for drift |
| `LockedIn/Features/Onboarding/ViewModels/OnboardingShellViewModel.swift` | Onboarding | ViewModel | Presentation state and feature orchestration | Small/medium (57 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Onboarding/Views/OnboardingShellView.swift` | Onboarding | View | UI rendering and user interaction composition | Medium-large (262 LOC) | Monitor for drift |
| `LockedIn/Features/Plan/Models/PlanModels.swift` | Plan | Model | Feature/domain data structures | Large (411 LOC) | Multi-responsibility risk |
| `LockedIn/Features/Plan/ViewModels/PlanViewModel.swift` | Plan | ViewModel | Presentation state and feature orchestration | Very large (604 LOC) | High split pressure |
| `LockedIn/Features/Plan/Views/PlanScreen.swift` | Plan | View | UI rendering and user interaction composition | Extreme ("2396 LOC") | God-file candidate |
| `LockedIn/Features/Recovery/Components/RecoveryProtocolSelectionCard.swift` | Recovery | Component | Reusable UI subview | Small/medium (88 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Recovery/Models/RecoveryFlowState.swift` | Recovery | Model | Feature/domain data structures | Small/medium (19 LOC) | No size hotspot by LOC |
| `LockedIn/Features/Recovery/ViewModels/RecoveryModeViewModel.swift` | Recovery | ViewModel | Presentation state and feature orchestration | Medium-large (181 LOC) | Monitor for drift |
| `LockedIn/Features/Recovery/Views/RecoveryModePopup.swift` | Recovery | View | UI rendering and user interaction composition | Medium-large (249 LOC) | Monitor for drift |
