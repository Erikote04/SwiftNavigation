# SwiftNavigation Implementation Plan

This document tracks the incremental delivery of the SwiftNavigation library.
All commit messages must follow Semantic Release conventions and be written in English.

## Delivery Phases

- [x] `feat(core): add type-safe navigation state primitives`
  - Add route constraints (`Codable`, `Hashable`, `Sendable`) and state models.
  - Add modal presentation state structures.
  - Ensure state snapshot is fully exportable and importable.

- [x] `feat(coordinator): implement main-actor navigation coordinator`
  - Add `@Observable` + `@MainActor` coordinator.
  - Implement stack operations (`push`, `pop`, `popToRoot`, `popToView`).
  - Implement modal operations with nested modal support.
  - Add child-coordinator lifecycle cleanup APIs.

- [x] `feat(routing-view): add SwiftUI routing wrapper with nested modal support`
  - Add `RoutingView` wrapper.
  - Integrate `NavigationStack`, `.sheet`, and `.fullScreenCover`.
  - Keep state in sync when the system dismisses modals via gesture.

- [x] `feat(integration): add environment injection and protocol-based routing abstractions`
  - Add environment-based coordinator injection helpers.
  - Add protocol abstractions for MVVM-C decoupling.
  - Add deep-link reconstruction interfaces.

- [x] `test(navigation): cover stack, modal recursion, restoration, and deeplink flows`
  - Add Swift Testing coverage for stack and modal behaviors.
  - Add async/main-actor focused tests for coordinator safety.

- [x] `docs(docc): add complete DocC guides and best-practice documentation`
  - Add a DocC catalog in English.
  - Add quick start, MVVM-C integration tutorial, restoration guide, and deep-linking guide.

## Follow-up (After Library Completion)

- Add CI workflow to publish documentation automatically on commits to `main`.
- Update project `README.md`.
- Optionally add an example app.
