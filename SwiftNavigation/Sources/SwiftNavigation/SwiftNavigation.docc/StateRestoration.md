# State Restoration

`NavigationCoordinator` can export and import complete navigation snapshots.

## Why It Works

- `StackRoute` and `ModalRoute` conform to ``NavigationRoute``.
- ``NavigationRoute`` requires `Codable` and `Hashable`.
- ``NavigationState`` includes both stack and nested modal state.

## Save Snapshot

```swift
let snapshot = coordinator.exportState()
let data = try JSONEncoder().encode(snapshot)
```

## Restore Snapshot

```swift
let snapshot = try JSONDecoder().decode(
    NavigationState<AppRoute, AppModalRoute>.self,
    from: data
)

coordinator.restore(from: snapshot)
```

## Recommended Use Cases

- Scene phase restoration.
- App relaunch continuation.
- Crash-safe checkpointing.
- UI test reproducibility for complex flows.
