# ``SwiftNavigation``

Type-safe, coordinator-driven navigation for SwiftUI apps using `NavigationStack`, `.sheet`, `.fullScreenCover`, and `.alert`.

## Overview

SwiftNavigation is a pure SwiftUI navigation layer for iOS 26+ that uses the Observation framework and an MVVM-C-friendly API.

Core goals:

- Strictly native SwiftUI navigation APIs only.
- `@Observable` + `@MainActor` state ownership in the coordinator.
- Entry-backed navigation so duplicate destinations stay uniquely addressable.
- Codable state snapshots for restoration and deep linking.
- Nested modal presentations with independent internal navigation.
- Global typed alerts and sheet-specific presentation controls.
- Async interception for login-gated external navigation.
- Protocol-based abstractions for ViewModel decoupling.

## Topics

### Essentials

- <doc:QuickStart>
- <doc:MVVMCoordinator>
- <doc:AlertsAndSheets>
- <doc:FlowBookmarks>
- <doc:DeepLinkInterception>
- <doc:UniversalLinks>
- <doc:MigrationGuide>
- <doc:BestPractices>

### Navigation State

- <doc:StateRestoration>
- <doc:DeepLinking>

### Core Symbols

- ``NavigationCoordinator``
- ``RoutingView``
- ``NavigationRouting``
- ``NavigationEntryID``
- ``NavigationEntry``
- ``NavigationState``
- ``ModalPresentation``
- ``AlertPresentation``
- ``AlertDescriptor``
- ``SheetPresentationOptions``
- ``NavigationInterceptionDecision``
