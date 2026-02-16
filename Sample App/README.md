# SwiftNavigation Sample App

A demo iOS app that showcases **MVVM-C navigation** using `SwiftNavigation` and async data fetching with `SwiftNetwork`, backed by the **Rick and Morty API**.

The sample intentionally demonstrates real navigation use cases:

- `TabView` root navigation
- push and pop flows
- `popToRoot`
- sheets and full-screen covers
- navigation inside modals
- nested modal presentations (modal over modal)

---

## What This App Demonstrates

- How to compose an app-level coordinator with feature-level coordinators.
- How ViewModels stay decoupled from SwiftUI navigation APIs through routing protocols.
- How `RoutingView` from `SwiftNavigation` drives root stack + recursive modal stack from coordinator state.
- How to integrate an actor-based service layer using `SwiftNetwork`.

---

## High-Level Architecture

### Layers

1. **UI (SwiftUI Views)**
- Renders tabs, lists, detail screens, and modal content.

2. **ViewModels (`@Observable`, `@MainActor`)**
- Own view state, load API data, and trigger navigation through protocols.

3. **Coordinators (MVVM-C)**
- Translate intent into navigation actions (`push`, `present`, `pop`, `popToRoot`, etc.).

4. **Network Service (`actor`)**
- Fetches and decodes Rick and Morty API data via `SwiftNetwork`.

---

## Folder Map

- `SwiftNavigationSampleApp/App`
  - `AppRoutes.swift`: typed route definitions
  - `AppCoordinator.swift`: app + feature coordinators
  - `AppRootView.swift`: root container with `RoutingView`
- `SwiftNavigationSampleApp/Networking`
  - `RickMortyService.swift`: actor-based service API
  - `RickMortyModels.swift`: API DTOs and route mapping
- `SwiftNavigationSampleApp/Features`
  - `Characters`: list/detail/episode flows
  - `Explore`: locations/settings/about flows
  - `Modals`: modal view models and nested modal views

---

## Coordinators, Step by Step

### 1) Route Contracts (`AppRoutes.swift`)

The app uses two typed route spaces:

- `AppRoute`: root `NavigationStack` routes (push-based).
- `AppModalRoute`: modal routes (`sheet` / `fullScreenCover`) including modal-internal navigation.

Both are `NavigationRoute` (`Codable + Hashable + Sendable`) so they are testable and serializable.

Route payloads (`CharacterRouteData`, `EpisodeRouteData`, `LocationRouteData`) carry lightweight data needed to bootstrap destination screens.

### 2) App-Level Composition (`AppCoordinator.swift`)

`AppCoordinator` owns and wires everything:

- `NavigationCoordinator<AppRoute, AppModalRoute>` as the single navigation state engine.
- `NavigationRouterProxy` as protocol-friendly routing adapter.
- Feature coordinators:
  - `CharactersCoordinator`
  - `ExploreCoordinator`
- Shared service:
  - `RickMortyService`
- Root ViewModels:
  - `CharactersListViewModel`
  - `LocationsListViewModel`

This makes feature wiring explicit and centralized.

### 3) Feature Coordinator Responsibilities

### `CharactersCoordinator`

Implements `CharactersRouting`:

- `showCharacterDetail` -> `push(.characterDetail(...))`
- `showEpisodeDetail` -> `push(.episodeDetail(...))`
- `showCharacterActions` -> `present(.characterActions(...), style: .sheet)`
- `popCurrent` -> `pop()`
- `popToRoot` -> `popToRoot()`

### `ExploreCoordinator`

Implements `ExploreRouting`:

- `showLocationDetail` -> push location detail
- `showSettings` -> present full-screen settings
- `showAbout` -> present about sheet

Feature ViewModels only know these protocol methods, not `SwiftUI` nor `NavigationCoordinator` internals.

### 4) Root Navigation Host (`AppRootView.swift`)

`AppRootView` uses:

- `RoutingView(coordinator: appCoordinator.navigationCoordinator, ...)`
- Root content = `TabView` with `Characters` and `Explore` tabs.
- `destination` maps `AppRoute` values to pushed screens.
- `modalDestination` maps `AppModalRoute` values to modal screens.

This is where the whole route graph is declared in one place.

### 5) End-to-End Navigation Walkthrough

### A) Push flow

1. User taps a character in `CharactersTabView`.
2. `CharactersListViewModel.didTapCharacter` calls `CharactersRouting.showCharacterDetail`.
3. `CharactersCoordinator` pushes `.characterDetail`.
4. `RoutingView` resolves route and shows `CharacterDetailView`.

### B) Pop / PopToRoot flow

- In `CharacterDetailView`, action buttons call ViewModel methods.
- ViewModel delegates to `CharactersCoordinator`.
- Coordinator calls `pop()` or `popToRoot()`.

### C) Modal + navigation inside modal

1. Character detail opens `characterActions` (sheet).
2. Inside `CharacterActionsModalView`, `NavigationLink(value: .characterEpisodes(...))` pushes **inside the modal stack**.
3. Episodes list can push modal episode detail (`.characterEpisodeDetail(...)`).

### D) Nested modal over modal

1. In character actions sheet, user opens `favoritesPlanner` as full-screen modal.
2. From planner, user opens `plannerConfirmation` as sheet.
3. This demonstrates recursive modal stacking managed by `SwiftNavigation`.

---

## Networking and ViewModels

`RickMortyService` is an `actor`, so all network access is serialized and concurrency-safe.

- Uses `NetworkClient` from `SwiftNetwork`.
- Provides async APIs for:
  - character list/detail
  - episode detail and batch episode fetch
  - location list/detail
- ViewModels call service methods with `await`, then update UI state on `@MainActor`.

---

## Why `nonisolated` on API Models

This sample target is configured with:

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`

That means declarations are MainActor-isolated by default. Without adjustments, DTO conformances such as `Decodable` can become main-actor-isolated, which conflicts when decoding in non-main actor contexts (for example in the `RickMortyService` actor and generic `Sendable` constraints).

So in `RickMortyModels.swift`, DTOs are declared with `nonisolated`:

- `APIPageInfo`
- `APIListResponse`
- `APINamedResource`
- `APICharacter`
- `APIEpisode`
- `APILocation`
- helper `extractID(...)`

This opts those data types out of implicit MainActor isolation and keeps decoding/sendability valid in concurrent contexts.

### If the target did **not** use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`

You typically would **not need** these `nonisolated` annotations.

In that setup, plain DTOs like this are enough:

```swift
struct APICharacter: Decodable, Sendable { ... }
```

So:

- With MainActor default isolation: use `nonisolated` for pure data DTOs used off-main actor.
- Without MainActor default isolation: regular structs are usually correct.

---

## Run the Sample

1. Open:
- `Sample App/SwiftNavigationSampleApp/SwiftNavigationSampleApp.xcodeproj`
2. Select scheme:
- `SwiftNavigationSampleApp`
3. Run on iOS Simulator.

---

## Suggested Reading Order in Code

1. `App/AppRoutes.swift`
2. `App/AppCoordinator.swift`
3. `App/AppRootView.swift`
4. `Features/Characters/*`
5. `Features/Explore/*`
6. `Features/Modals/*`
7. `Networking/RickMortyService.swift`
8. `Networking/RickMortyModels.swift`

Following this order gives you the clearest top-down understanding of the MVVM-C flow.
