# Flow Bookmarks

SwiftNavigation v2 adds stable entry identifiers so repeated routes remain uniquely addressable.

## Why Entry IDs Matter

Route equality alone is not enough when a flow can revisit the same screen multiple times.

Examples:

- editing the same amount screen twice inside one payment flow
- reopening the same profile route from different steps
- jumping back to a specific screen from a review page

`NavigationEntryID` solves that by identifying the navigation instance, not just the route value.

## Root Stack Bookmarks

`push(_:)` now returns the entry ID assigned to the pushed route:

```swift
let recipientID = coordinator.push(.recipient)
let amountID = coordinator.push(.amount)
_ = coordinator.push(.review)

coordinator.popToEntry(amountID)
```

You can also inspect `stackEntries` directly when you need route-plus-ID state together.

## Modal Path Bookmarks

Modal flows have the same concept for their internal `NavigationStack`:

```swift
_ = coordinator.present(.sendMoney, style: .sheet)

let firstAmountID = coordinator.pushModalRoute(.amount, at: 0)
let secondAmountID = coordinator.pushModalRoute(.amount, at: 0)

if let secondAmountID {
    coordinator.popModalToEntry(secondAmountID, at: 0)
}
```

Use `modalPathEntries(at:)` to read the current modal path with stable identifiers.

## Recommended Pattern

Store returned entry IDs inside your feature ViewModel or feature coordinator when the user opens editable steps. Later, use those IDs from a review screen or summary screen to jump back to the exact step the user wants to change.

That pattern is what powers the sample app's send-money flow.
