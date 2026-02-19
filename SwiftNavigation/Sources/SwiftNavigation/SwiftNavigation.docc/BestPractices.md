# Best Practices

Guidelines for robust and scalable coordinator flows.

## Keep Navigation Mutations on Main Actor

`NavigationCoordinator` is `@MainActor`, so all push/pop/present/dismiss operations are serialized for UI safety.

## Prefer Narrow Routing Protocols in ViewModels

Avoid exposing all coordinator methods everywhere. Define feature-focused protocols and inject only the required actions.

## Use Scoped Coordinators

Use ``CoordinatorScope`` to separate concerns:

- `.application` for top-level app flow.
- `.tab(name:)` for tab-specific stacks.
- `.feature(name:)` for isolated feature modules.

## Clean Child Coordinators Proactively

When a child flow ends, mark it as finished and call `cleanupChildCoordinators()` on the parent. This keeps ownership lean and avoids stale references.

## Preserve Native User Behavior

Do not override standard system back gestures and sheet dismissal behavior. Let SwiftUI own those interactions and synchronize state through coordinator updates.

## Keep Routes Stable and Codable

Routes should encode durable identifiers (IDs, slugs, enums) instead of volatile in-memory values.

## Test with Swift Testing

Write deterministic tests around pure coordinator operations (stack transitions, modal transitions, restoration, and deep links) before wiring UI.
