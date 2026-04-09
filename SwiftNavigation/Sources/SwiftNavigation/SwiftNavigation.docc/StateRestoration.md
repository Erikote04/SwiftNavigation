# State Restoration

`NavigationCoordinator` can export and import complete navigation snapshots.

## Why It Works

- `StackRoute` and `ModalRoute` conform to ``NavigationRoute``.
- ``NavigationRoute`` requires `Codable` and `Hashable`.
- ``NavigationState`` includes entry-backed root stacks, nested modal state, and the active alert.
- Legacy route-only snapshots still decode and synthesize missing entry identifiers.

## Save Snapshot

```swift
let snapshot = coordinator.exportState()
let data = try JSONEncoder().encode(snapshot)
```

## Restore Snapshot

```swift
let snapshot = try JSONDecoder().decode(
    NavigationState<AppRoute, AppModalRoute, AppAlertRoute>.self,
    from: data
)

coordinator.restore(from: snapshot)
```

## Recommended Use Cases

- Scene phase restoration.
- App relaunch continuation.
- Crash-safe checkpointing.
- UI test reproducibility for complex flows.

`exportState()` intentionally captures current stack, modal, and alert state. Pending intercepted navigation is stored separately on the coordinator and can be managed with `resumePendingNavigation()` and `clearPendingNavigation()`.
