---
name: swift-navigation-skill
description: Integrate the SwiftNavigation library into SwiftUI apps. Use when building or refactoring SwiftNavigation routes, app or child coordinators, router proxies, MVVM-C view models, dependency injection, sheets, full screen covers, coordinator-driven alerts, URL or notification deep links, universal links, login interception, flow bookmarks with NavigationEntryID, or navigation state persistence and restoration.
---

# SwiftNavigation Skill

## Overview

Implement SwiftNavigation using the library's intended MVVM-C pattern: typed route enums and payload structs, one root `NavigationCoordinator`, feature coordinators backed by `NavigationRouterProxy`, `@Observable` view models injected with routing protocols, and a single `RoutingView` that maps stacks, modals, and alerts.

## Start Here

- Load [references/workflow.md](references/workflow.md) first for the end-to-end implementation sequence.
- Load only the additional references needed for the current task:
  - [references/routes-and-state.md](references/routes-and-state.md)
  - [references/coordinators-and-di.md](references/coordinators-and-di.md)
  - [references/presentation.md](references/presentation.md)
  - [references/deep-links-and-universal-links.md](references/deep-links-and-universal-links.md)
  - [references/state-restoration.md](references/state-restoration.md)
- Prefer the public API and patterns documented by SwiftNavigation over inventing parallel navigation abstractions.

## Core Rules

- Keep one root `NavigationCoordinator<StackRoute, ModalRoute, AlertRoute>` per app root or scene.
- Model routes as `NavigationRoute` values that stay `Codable`, `Hashable`, and easy to decode from persisted snapshots and deep links.
- Use structs for payload-heavy routes and enums for the top-level route namespaces.
- Hide navigation behind routing protocols when injecting into view models.
- Keep feature coordinators `@MainActor` and back them with `NavigationRouterProxy`.
- Let `RoutingView` own stack, modal, and alert rendering. Do not recreate competing view-local navigation state.
- Use `Never` for `AlertRoute` only when the app truly does not need coordinator-driven alerts.
- Store returned `NavigationEntryID` values whenever a flow must revisit or precisely target repeated destinations.
- Rebuild full `NavigationState` values in deep-link resolvers instead of imperatively replaying navigation from views.
- Intercept protected deep links asynchronously and resume them after login with `resumePendingNavigation()`.
- Persist coordinator snapshots with `exportState()` and restore them with `restore(from:)`.

## Recommended Workflow

1. Define `AppRoute`, `AppModalRoute`, and `AppAlertRoute` with the guidance in [references/routes-and-state.md](references/routes-and-state.md).
2. Create the app/root coordinator, shared `NavigationRouterProxy`, services, and child coordinators with [references/coordinators-and-di.md](references/coordinators-and-di.md).
3. Inject routing protocols into `@Observable` view models instead of handing them the full app coordinator.
4. Build the single `RoutingView` root and map stack, modal, and alert destinations with [references/presentation.md](references/presentation.md).
5. Add `NavigationEntryID` bookmarks for editable or repeated flow steps.
6. Add URL and notification resolvers, universal-link entry points, and optional login interception with [references/deep-links-and-universal-links.md](references/deep-links-and-universal-links.md).
7. Persist and restore snapshots with [references/state-restoration.md](references/state-restoration.md).
8. Verify behavior by asserting coordinator state directly in tests.

## Decision Heuristics

- Put browser-like push navigation in `AppRoute`.
- Put sheets and full screen covers in `AppModalRoute`.
- Put coordinator-owned confirmations and error messaging in `AppAlertRoute`.
- Add a child coordinator when a feature needs its own routing contract or reusable flow logic.
- Store `NavigationEntryID` when route equality alone is not enough to target the right screen later.
- Use a deep-link interceptor when auth, onboarding, or a feature gate must run before the destination applies.

## Avoid

- Do not keep long-lived sheet, alert, or navigation booleans in feature views when the coordinator can own them.
- Do not inject the full root coordinator into every view model when a focused routing protocol is enough.
- Do not drive deep links by calling several `push` or `present` methods from `onOpenURL`.
- Do not rely only on route equality when the same route can appear more than once in a flow.
- Do not store raw SwiftUI alert state in view models when `AlertDescriptor` mapping can stay in `RoutingView`.

## Output Expectations

- Produce or update typed routes, coordinators, routing protocols, view-model injection, `RoutingView` mapping, deep-link resolvers, and persistence code together as one coherent integration.
- Keep naming explicit and Swift-friendly.
- Follow SwiftUI, Swift Concurrency, and MVVM-C best practices reflected in the SwiftNavigation documentation and maintained examples.
