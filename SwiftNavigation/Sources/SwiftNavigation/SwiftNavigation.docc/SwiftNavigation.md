# ``SwiftNavigation``

Type-safe, coordinator-driven navigation for SwiftUI apps using `NavigationStack`, `.sheet`, and `.fullScreenCover`.

## Overview

SwiftNavigation is a pure SwiftUI navigation layer for iOS 17+ that uses the Observation framework and an MVVM-C-friendly API.

Core goals:

- Strictly native SwiftUI navigation APIs only.
- `@Observable` + `@MainActor` state ownership in the coordinator.
- Type-safe route stacks backed by plain arrays.
- Codable state snapshots for restoration and deep linking.
- Nested modal presentations with independent internal navigation.
- Protocol-based abstractions for ViewModel decoupling.

## Topics

### Essentials

- <doc:QuickStart>
- <doc:MVVMCoordinator>
- <doc:BestPractices>

### Navigation State

- <doc:StateRestoration>
- <doc:DeepLinking>

### Core Symbols

- ``NavigationCoordinator``
- ``RoutingView``
- ``NavigationRouting``
- ``NavigationState``
- ``ModalPresentation``
