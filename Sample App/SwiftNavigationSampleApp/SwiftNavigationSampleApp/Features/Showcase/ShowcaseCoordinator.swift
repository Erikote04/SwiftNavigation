import Foundation
import SwiftNavigation

@MainActor
protocol ShowcaseRouting: AnyObject {
    func startSendMoneyFlow()
    func showAmountEditor(_ route: SendMoneyAmountRouteData) -> NavigationEntryID
    func showReview(_ route: SendMoneyReviewRouteData) -> NavigationEntryID
    func showProtectedReceipt(_ route: ProtectedReceiptRouteData) -> NavigationEntryID
    func showProtectedProfile(_ route: ProtectedProfileRouteData) -> NavigationEntryID
    func currentEntryID(for route: AppRoute) -> NavigationEntryID?
    func popToEntry(_ id: NavigationEntryID)
    func popToRoot()
    func showMaterialSheetShowcase()
    func showClearSheetShowcase()
    func showProtectedLoginSheet()
    func showAlertShowcaseModal()
    func showErrorAlert(_ message: String)
    func showDiscardDraftConfirmation(flowID: UUID)
    func dismissTopModal()
}

@MainActor
final class ShowcaseCoordinator: CoordinatorLifecycle, ShowcaseRouting {
    let coordinatorID = UUID()

    private let router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>

    init(router: NavigationRouterProxy<AppRoute, AppModalRoute, AppAlertRoute>) {
        self.router = router
    }

    var isFlowFinished: Bool {
        false
    }

    func startSendMoneyFlow() {
        let route = SendMoneyRecipientRouteData(
            flowID: UUID(),
            selectedRecipient: "Sonia",
            availableRecipients: ["Sonia", "Alex", "Maya", "Taylor"]
        )
        _ = router.push(.sendMoneyRecipient(route))
    }

    func showAmountEditor(_ route: SendMoneyAmountRouteData) -> NavigationEntryID {
        router.push(.sendMoneyAmount(route))
    }

    func showReview(_ route: SendMoneyReviewRouteData) -> NavigationEntryID {
        router.push(.sendMoneyReview(route))
    }

    func showProtectedReceipt(_ route: ProtectedReceiptRouteData) -> NavigationEntryID {
        router.push(.protectedReceipt(route))
    }

    func showProtectedProfile(_ route: ProtectedProfileRouteData) -> NavigationEntryID {
        router.push(.protectedProfile(route))
    }

    func currentEntryID(for route: AppRoute) -> NavigationEntryID? {
        router.stackEntries.last(where: { $0.route == route })?.id
    }

    func popToEntry(_ id: NavigationEntryID) {
        _ = router.popToEntry(id)
    }

    func popToRoot() {
        router.popToRoot()
    }

    func showMaterialSheetShowcase() {
        _ = router.present(
            .sheetShowcase(
                SheetShowcaseRouteData(
                    title: "Material sheet",
                    subtitle: "Medium and large detents with background interaction.",
                    details: "Use this pattern for quick actions that still keep the main context visible behind the sheet.",
                    variant: .material,
                    systemImage: "square.3.layers.3d.down.right"
                )
            ),
            style: .sheet,
            sheetPresentation: SheetPresentationOptions(
                detents: [.medium, .large],
                background: .thinMaterial,
                backgroundInteraction: .enabledThrough(.medium)
            )
        )
    }

    func showClearSheetShowcase() {
        _ = router.present(
            .sheetShowcase(
                SheetShowcaseRouteData(
                    title: "Clear sheet",
                    subtitle: "A lighter presentation that feels closer to an overlay.",
                    details: "This demonstrates a clear background when the content itself carries the visual grouping.",
                    variant: .clear,
                    systemImage: "rectangle.transparent"
                )
            ),
            style: .sheet,
            sheetPresentation: SheetPresentationOptions(
                detents: [.medium, .large],
                background: .clear,
                backgroundInteraction: .disabled
            )
        )
    }

    func showProtectedLoginSheet() {
        _ = router.present(
            .login(
                LoginRouteData(
                    title: "Locked login sheet",
                    message: "This demo uses interactive dismissal blocking to mimic a protected deep link that requires authentication first.",
                    source: "Sheet showcase",
                    isDismissDisabled: true
                )
            ),
            style: .sheet,
            sheetPresentation: SheetPresentationOptions(
                detents: [.medium, .large],
                background: .regularMaterial,
                backgroundInteraction: .enabledThrough(.medium),
                interactiveDismissDisabled: true
            )
        )
    }

    func showAlertShowcaseModal() {
        _ = router.present(
            .alertShowcase,
            style: .sheet,
            sheetPresentation: SheetPresentationOptions(
                detents: [.medium],
                background: .thinMaterial
            )
        )
    }

    func showErrorAlert(_ message: String) {
        _ = router.presentAlert(.showcaseError(message))
    }

    func showDiscardDraftConfirmation(flowID: UUID) {
        _ = router.presentAlert(.discardDraft(flowID))
    }

    func dismissTopModal() {
        _ = router.dismissTopModal()
    }
}
