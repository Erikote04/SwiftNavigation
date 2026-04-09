# Routes and Navigation State

## Design Routes for Persistence and Deep Links

- Make every route conform to `NavigationRoute`.
- Prefer enums for the route namespaces:

```swift
enum AppRoute: NavigationRoute {
    case dashboard
    case profile(ProfileRouteData)
}
```

- Prefer structs for payload-heavy route data:

```swift
struct ProfileRouteData: NavigationRoute {
    let userID: UUID
    let displayName: String
    let source: String
}
```

- Keep payloads stable enough to encode, restore, and reconstruct from URLs or notifications.

## Split the Route Surface Intentionally

- Put pushed destinations in `AppRoute`.
- Put sheets and full screen covers in `AppModalRoute`.
- Put coordinator-owned alerts in `AppAlertRoute`.

```swift
enum AppModalRoute: NavigationRoute {
    case signIn(SignInRouteData)
    case settings
}

enum AppAlertRoute: NavigationRoute {
    case errorMessage(String)
    case discardChanges(UUID)
}
```

## Use Entry IDs for Exact Navigation

Route equality is not enough when the same route can appear multiple times.

Use:

- `let id = coordinator.push(.profile(route))`
- `coordinator.popToEntry(id)`
- `coordinator.containsEntry(id)`

Store those identifiers in a view model or feature coordinator when the user may later say "take me back to the amount screen I just edited".

## Use Modal Path Entry IDs for Nested Modal Flows

For navigation inside a presented modal:

- `pushModalRoute(_:at:)`
- `modalPathEntries(at:)`
- `popModalToEntry(_:at:)`
- `containsModalEntry(_:at:)`

Use these when a modal hosts its own `NavigationStack` and repeated screens must still be individually addressable.

## Build `NavigationState` Directly When Needed

`NavigationState` is the canonical snapshot for:

- deep links
- universal links
- notification payloads
- persistence and restoration
- test setup

Examples:

```swift
let state = NavigationState<AppRoute, AppModalRoute, AppAlertRoute>(
    stack: [.profile(profileRoute)],
    modalStack: [.init(style: .sheet, root: .signIn(signInRoute))]
)
```

Or with entry-backed values:

```swift
let state = NavigationState<AppRoute, AppModalRoute, AppAlertRoute>(
    stackEntries: [
        NavigationEntry(route: .profile(profileRoute))
    ]
)
```

## Keep Routes Reviewable

- Prefer descriptive case names such as `.profile`, `.editor`, `.receipt`.
- Avoid route cases that simply mirror view names without domain meaning.
- Keep route payloads free of live service references or non-`Codable` UI state.
- Store identifiers, values, and lightweight display context, not whole feature objects.
