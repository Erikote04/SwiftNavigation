# State Restoration

## Persist the Coordinator Snapshot

Use `exportState()` as the canonical serialization source:

```swift
let snapshot = coordinator.exportState()
let data = try JSONEncoder().encode(snapshot)
userDefaults.set(data, forKey: "navigationState")
```

Persist this from the app/root coordinator or scene-level composition root.

## Restore Early

Restore as early as possible in app startup, after the root coordinator exists and before the user starts navigating again:

```swift
if let data = userDefaults.data(forKey: "navigationState") {
    let snapshot = try JSONDecoder().decode(
        NavigationState<AppRoute, AppModalRoute, AppAlertRoute>.self,
        from: data
    )
    coordinator.restore(from: snapshot)
}
```

## Handle Decode Failure Gracefully

If decoding fails:

- remove the invalid snapshot
- log or assert in debug builds
- continue with a clean coordinator state

## Know What Gets Stored

`exportState()` captures:

- entry-backed root stack state
- modal stack state
- modal path entries
- the active alert presentation

Pending intercepted navigation is stored separately on the coordinator. Manage that with:

- `resumePendingNavigation()`
- `clearPendingNavigation()`

## Use Cases

- app relaunch continuation
- scene restoration
- crash-safe checkpoints
- deterministic test setup for complex flows

## Compatibility Note

SwiftNavigation can decode legacy route-only snapshots and synthesize missing entry identifiers during restore. Do not add your own migration layer unless the app wraps route data in an app-specific envelope.
