# Codex iOS Engineering Rules
Version: 1.0

This document defines mandatory engineering standards for this Swift iOS project.

Codex must follow these rules when generating or modifying code.

Codex behaves like a junior engineer guided by a senior architect.

If a request violates these rules, Codex must propose a compliant solution instead.

---

# 1. Core Engineering Principles

These principles override all other instructions.

Rules:

- Never implement quick hacks or temporary fixes.
- Always diagnose the root cause of a problem.
- Never introduce technical debt silently.
- Prefer architectural solutions over patches.
- Keep the codebase production-ready at all times.

If something feels hacky:

1. Fix it immediately
OR
2. Document it with a TODO and explanation.

---

# 2. Architecture Standard

All features must follow:

MVVM + Clean Architecture.

Layers must be separated.

Presentation Layer
- SwiftUI Views
- ViewModels

Domain Layer
- Entities
- UseCases
- Protocols

Data Layer
- Repositories
- API Clients
- Persistence

Dependency Direction:

View -> ViewModel -> UseCase -> Repository -> API/Database

Never reverse dependencies.

---

# 3. Separation of Responsibilities

Responsibilities must be strictly enforced.

Views
- UI rendering
- user interactions
- no business logic

ViewModels
- UI state
- UI transformations
- calling UseCases

UseCases
- business rules
- orchestration of repositories

Repositories
- data access
- networking
- persistence

Entities
- pure domain models

Rules:

Views must NEVER:
- perform networking
- contain business logic

ViewModels must NEVER:
- call URLSession
- contain database logic

UseCases must NOT depend on UI frameworks.

---

# 4. SwiftUI Development Rules

SwiftUI views must remain small and declarative.

Rules:

- Views must not exceed 150 lines
- Break complex views into subviews
- Extract reusable components early
- Avoid nested view hierarchies > 4 levels

State management rules:

Allowed:

@State
@StateObject
@ObservedObject
@EnvironmentObject

Avoid:

- global mutable state
- business logic inside Views

---

# 5. File Structure

The project must follow this structure.

App/
    App.swift

Core/
    Networking/
    Persistence/
    Logging/
    Utilities/
    Extensions/

DesignSystem/
    Components/
    Styles/
    Themes/

Features/
    FeatureName/
        Views/
        ViewModels/
        UseCases/
        Repositories/
        Models/

Tests/
    UnitTests/
    UITests/

Each feature must be self-contained.

---

# 6. ViewModel Rules

ViewModels manage state and coordinate business logic.

Rules:

- Must be testable
- Must expose published state
- Must not contain UI layout code
- Must not perform networking directly

Example responsibilities:

- formatting data for views
- loading data via UseCases
- error state management

---

# 7. Networking Rules

Networking must go through a service layer.

Architecture:

APIClient -> Repository -> UseCase -> ViewModel

Rules:

- Never call URLSession directly from Views or ViewModels
- All networking must use async/await
- All responses must use typed models
- All errors must be handled

Example:

NetworkService
Repository
UseCase

---

# 8. Error Handling

Errors must never be ignored.

Rules:

- All async operations must handle failure
- Use typed error enums
- Surface errors to the UI

Example:

enum NetworkError: Error {
    case invalidResponse
    case decodingFailed
    case serverError
}

Never use try! in production code.

---

# 9. Logging

Console printing is forbidden in production.

Use structured logging.

Preferred:

Logger
OSLog

Logs must include:

- subsystem
- category

Example:

Logger.network.info("Request started")

---

# 10. Security Rules

Security practices must always be followed.

Never:

- hardcode API keys
- commit secrets
- store tokens in plaintext

Use:

- Keychain for sensitive data
- environment configs
- secure storage

All network calls must use HTTPS.

---

# 11. Dependency Management

Use Swift Package Manager only.

Rules:

- Avoid unnecessary libraries
- Prefer Apple native frameworks
- Lock dependency versions

Before adding a dependency:

Ask:
"Can this be implemented natively?"

---

# 12. Concurrency

Use modern Swift concurrency.

Preferred:

async/await

Avoid:

- callback hell
- nested completion handlers

Long-running tasks must be off the main thread.

---

# 13. Testing Rules

All business logic must be testable.

Required tests:

UseCases
ViewModels
Repositories

Test cases must include:

- happy path
- failure scenarios
- edge cases

Views do not require tests unless logic exists.

---

# 14. Performance Rules

Rules:

- Avoid heavy computation inside Views
- Cache expensive operations
- Avoid unnecessary state updates
- Prevent excessive re-rendering

Use Instruments when performance issues arise.

---

# 15. Refactoring Discipline

Codex must proactively refactor when code becomes too complex.

Refactor when:

- file > 300 lines
- view > 150 lines
- class has multiple responsibilities
- duplicate logic appears

Never allow:

- "God classes"
- massive view controllers
- duplicated logic

---

# 16. Feature Development Workflow

When implementing a feature:

Step 1 - Analyze existing architecture
Step 2 - Design the change
Step 3 - Confirm design
Step 4 - Implement code
Step 5 - Refactor if needed
Step 6 - Ensure testability

---

# 17. Code Reuse Rules

Before writing new code:

1. Search for existing components
2. Reuse utilities
3. Avoid duplication

Prefer:

protocols
extensions
dependency injection

---

# 18. SOLID Principles

All code must follow SOLID principles.

Single Responsibility
Open / Closed
Liskov Substitution
Interface Segregation
Dependency Inversion

Prefer:

composition over inheritance

---

# 19. Code Quality Standards

Naming:

Use descriptive names.

Avoid abbreviations.

Example:

Bad

vm
svc

Good

AuthenticationViewModel
UserRepository

---

# 20. Codex Behavior Rules

Codex must:

- analyze architecture before coding
- reuse existing code
- avoid duplication
- propose refactoring when necessary
- explain architectural changes

Codex must NOT:

- introduce new architecture patterns without justification
- bypass the architecture layers
- mix UI, business logic, and networking

---

# Final Rule

Code must be:

- maintainable
- testable
- scalable
- production-ready
