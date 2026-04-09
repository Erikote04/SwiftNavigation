# SwiftNavigation Integration Workflow

## Purpose

Follow this sequence when integrating SwiftNavigation into a new or existing SwiftUI app.

## Sequence

1. Define the route surface.
2. Build the root coordinator and composition root.
3. Add child coordinators and routing protocols.
4. Connect routing to `@Observable` view models.
5. Build the `RoutingView` container.
6. Add flow bookmarks for repeated destinations.
7. Add deep links, universal links, and notification entry points.
8. Add persistence and restoration.
9. Verify with direct coordinator-state assertions.

## 1. Define the Route Surface

- Create `AppRoute` for root stack navigation.
- Create `AppModalRoute` for sheets and full screen covers.
- Create `AppAlertRoute` for coordinator-owned alerts. Use `Never` only when you do not need global typed alerts.
- Keep route payloads small, explicit, and `Codable`.

Load [routes-and-state.md](routes-and-state.md) before implementing this step.

## 2. Build the Root Coordinator and Composition Root

- Create one `NavigationCoordinator<AppRoute, AppModalRoute, AppAlertRoute>` at the app root.
- Create one shared `NavigationRouterProxy` from that coordinator.
- Construct app-wide dependencies here: services, repositories, session stores, clocks, UUID generators, and feature coordinators.
- Attach child coordinators with `attachChild(_:)` when they conform to `CoordinatorLifecycle`.

Load [coordinators-and-di.md](coordinators-and-di.md) before implementing this step.

## 3. Add Child Coordinators

- Give each feature a narrow routing protocol such as `PaymentRouting` or `ProfileRouting`.
- Implement that protocol in a feature coordinator backed by `NavigationRouterProxy`.
- Return `NavigationEntryID` from routing methods when later exact back-navigation is likely.

## 4. Connect View Models

- Inject the feature routing protocol into `@Observable` view models.
- Keep views focused on rendering and wiring button taps to view-model methods.
- Let view models decide when to navigate, but not how SwiftUI presents destinations.

## 5. Build the Routing Container

- Wrap the root UI in one `RoutingView`.
- Map `AppRoute` in `stackDestination`.
- Map `AppModalRoute` in `modalDestination`.
- Map `AppAlertRoute` in `alertDestination` if alerts are enabled.
- Apply `.navigationCoordinator(coordinator)` to the root container.

Load [presentation.md](presentation.md) before implementing this step.

## 6. Add Flow Bookmarks

- Capture the result of `push(_:)` for steps that may need later editing.
- For modal-internal flows, use `pushModalRoute(_:at:)`.
- Use `popToEntry(_:)` or `popModalToEntry(_:at:)` to jump back to an exact screen instance.

Load [routes-and-state.md](routes-and-state.md) before implementing this step.

## 7. Add External Navigation

- Implement a `URLDeepLinkResolving` type for URL and universal-link inputs.
- Implement a `NotificationDeepLinkResolving` type for notification payloads.
- Rebuild full `NavigationState` snapshots from those inputs.
- Add interception when login or another prerequisite must run first.

Load [deep-links-and-universal-links.md](deep-links-and-universal-links.md) before implementing this step.

## 8. Add Persistence

- Save `exportState()` to disk when the app backgrounds or when you want checkpoints.
- Restore `NavigationState` early in app startup.
- Clear invalid or outdated snapshots if decoding fails.

Load [state-restoration.md](state-restoration.md) before implementing this step.

## 9. Verify

- Assert `stackEntries`, `modalStack`, `alertPresentation`, and `pendingNavigationState` directly in tests.
- Verify duplicated routes still behave correctly with `NavigationEntryID`.
- Verify protected deep links redirect to login and resume correctly.

## Integration Checklist

- Routes are typed and `Codable`.
- The app has one root coordinator.
- View models depend on routing protocols, not SwiftUI.
- `RoutingView` is the single navigation container.
- Sheets, alerts, and full screen covers come from the coordinator.
- Deep links rebuild `NavigationState`.
- Universal links reuse the same URL resolver pipeline.
- State snapshots save and restore cleanly.
