# SwiftNavigation Sample App

The sample app now showcases both the original Rick and Morty flows and the new SwiftNavigation v2 feature set.

## What To Explore

- `Characters` tab: classic push, sheet, full-screen, and nested-modal MVVM-C flows.
- `Explore` tab: location routes plus legacy-style modal navigation.
- `Showcase` tab: the new v2 demos.

The `Showcase` area is where the new library behavior is exercised:

- send-money flow with exact back navigation via `NavigationEntryID`
- repeated amount editors to prove duplicate routes remain uniquely addressable
- coordinator-driven alerts from both root content and a modal
- configurable sheets with detents, background material, background interaction, and non-dismissible login
- deep-link interception that redirects expired sessions to login and resumes the pending destination after sign-in
- shared parsing for custom schemes and `https` universal-link style URLs

## Architecture Snapshot

- `AppCoordinator` owns a single `NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>`.
- Feature-level coordinators (`CharactersCoordinator`, `LocationsCoordinator`, `ShowcaseCoordinator`) translate intent into navigation actions.
- ViewModels stay SwiftUI-agnostic by depending on routing protocols instead of `NavigationCoordinator` directly.
- `RoutingView` in `AppRootView` declares the entire route graph in one place, including `alertDestination`.
- `SessionStore` models authentication state for login interception and protected destinations.

## Showcase Folder Map

- `SwiftNavigationSampleApp/App`
  - `AppRoutes.swift`: stack, modal, and alert route contracts
  - `AppCoordinator.swift`: root composition, persistence, deep-link interception
  - `AppDeepLinking.swift`: URL and notification resolvers for both custom schemes and `https`
  - `AppRootView.swift`: root `RoutingView`, tabs, modal routing, and alerts
- `SwiftNavigationSampleApp/Features/Showcase`
  - `SendMoney/*`: entry-bookmark flow and exact back navigation demo
  - `Modal/*`: login, sheets, and modal alert demos
  - `Protected/*`: login-gated profile and receipt destinations
  - `SessionStore.swift`: lightweight auth state
  - `ShowcaseCoordinator.swift`: showcase-specific routing adapter
- `SwiftNavigationSampleAppTests`
  - `ShowcaseSampleAppTests.swift`: Swift Testing coverage for routing, interception, and deep-link parsing

## Deep Link Examples

### Custom scheme

- `swiftnavsample://characters/1?episode=28`
- `swiftnavsample://locations/3?about=1`
- `swiftnavsample://showcase/send-money?recipient=Sonia`
- `swiftnavsample://showcase/profile?displayName=Sonia`

### HTTPS / universal-link style URLs

- `https://demo.swiftnavigation.app/showcase/send-money?recipient=Sonia`
- `https://demo.swiftnavigation.app/showcase/profile?displayName=Sonia`
- `https://demo.swiftnavigation.app/showcase/receipt?recipient=Sonia&amount=35`

### Notification payloads

- `["target": "send-money", "recipient": "Sonia"]`
- `["target": "profile", "displayName": "Sonia"]`
- `["target": "receipt", "recipient": "Sonia", "amount": 35]`
- `["deeplink_url": "https://demo.swiftnavigation.app/showcase/profile"]`

## Simulator Walkthrough

1. Open `Sample App/SwiftNavigationSampleApp/SwiftNavigationSampleApp.xcodeproj`.
2. Select the `SwiftNavigationSampleApp` scheme.
3. Run on an iOS 26 simulator.
4. Open the `Showcase` tab.
5. Tap the session toolbar action to expire the current session.
6. Trigger a protected deep link and verify the login sheet appears first.
7. Complete login and verify `resumePendingNavigation()` takes you to the original destination.

If you want to drive URLs from the simulator:

```bash
xcrun simctl openurl booted 'swiftnavsample://showcase/send-money?recipient=Sonia'
xcrun simctl openurl booted 'https://demo.swiftnavigation.app/showcase/receipt?recipient=Sonia&amount=35'
```

## Universal Link Note

The sample app already parses `https` URLs through the same resolver pipeline and wires both `.onOpenURL` and `NSUserActivityTypeBrowsingWeb` into the coordinator.

End-to-end universal-link activation still requires:

- a real HTTPS host
- an `apple-app-site-association` file served by that host
- an `applinks:` Associated Domains entitlement on the app target

The placeholder sample domain demonstrates the routing behavior, not live production association.

## Tests And Verification

Package tests:

```bash
swift test
```

Sample app showcase tests:

```bash
xcodebuild \
  -project 'Sample App/SwiftNavigationSampleApp/SwiftNavigationSampleApp.xcodeproj' \
  -scheme SwiftNavigationSampleApp \
  -destination 'platform=iOS Simulator,id=8DE52934-0BE7-4772-B5D7-EB91450783F8' \
  -only-testing:SwiftNavigationSampleAppTests \
  test
```

Those sample tests cover:

- custom-scheme send-money parsing
- `https` receipt parsing
- login interception with pending-state resume
- exact back navigation with duplicated amount routes
