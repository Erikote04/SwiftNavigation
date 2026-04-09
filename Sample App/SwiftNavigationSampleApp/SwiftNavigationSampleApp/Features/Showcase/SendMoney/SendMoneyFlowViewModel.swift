import Foundation
import Observation
import SwiftNavigation

@MainActor
@Observable
final class SendMoneyFlowViewModel {
    private weak var router: (any ShowcaseRouting)?

    let flowID: UUID

    var selectedRecipient: String
    var availableRecipients: [String]
    var primaryAmount: Double
    var duplicateAmount: Double

    private(set) var recipientEntryID: NavigationEntryID?
    private(set) var primaryAmountEntryID: NavigationEntryID?
    private(set) var duplicateAmountEntryID: NavigationEntryID?

    init(
        flowID: UUID,
        router: any ShowcaseRouting,
        selectedRecipient: String = "Sonia",
        availableRecipients: [String] = ["Sonia", "Alex", "Maya", "Taylor"],
        primaryAmount: Double = 35,
        duplicateAmount: Double = 48
    ) {
        self.flowID = flowID
        self.router = router
        self.selectedRecipient = selectedRecipient
        self.availableRecipients = availableRecipients
        self.primaryAmount = primaryAmount
        self.duplicateAmount = duplicateAmount
    }

    func sync(with route: SendMoneyRecipientRouteData) {
        selectedRecipient = route.selectedRecipient
        availableRecipients = route.availableRecipients
        recipientEntryID = recipientEntryID ?? router?.currentEntryID(for: .sendMoneyRecipient(route))
    }

    func sync(with route: SendMoneyAmountRouteData) {
        selectedRecipient = route.selectedRecipient
        recipientEntryID = route.recipientEntryID

        switch route.editorKind {
        case .primary:
            primaryAmount = route.amount
            primaryAmountEntryID = router?.currentEntryID(for: .sendMoneyAmount(route)) ?? primaryAmountEntryID
        case .duplicate:
            duplicateAmount = route.amount
            duplicateAmountEntryID = router?.currentEntryID(for: .sendMoneyAmount(route)) ?? duplicateAmountEntryID
        }
    }

    func sync(with route: SendMoneyReviewRouteData) {
        selectedRecipient = route.selectedRecipient
        primaryAmount = route.primaryAmount
        duplicateAmount = route.duplicateAmount
        recipientEntryID = route.recipientEntryID
        primaryAmountEntryID = route.primaryAmountEntryID
        duplicateAmountEntryID = route.duplicateAmountEntryID
    }

    func continueFromRecipient(route: SendMoneyRecipientRouteData) {
        sync(with: route)
        recipientEntryID = router?.currentEntryID(for: .sendMoneyRecipient(route)) ?? recipientEntryID

        guard let recipientEntryID else {
            router?.showErrorAlert("The flow could not bookmark the recipient step.")
            return
        }

        let amountRoute = SendMoneyAmountRouteData(
            flowID: flowID,
            selectedRecipient: selectedRecipient,
            amount: primaryAmount,
            recipientEntryID: recipientEntryID,
            editorKind: .primary
        )
        primaryAmountEntryID = router?.showAmountEditor(amountRoute)
    }

    func continueFromAmount(route: SendMoneyAmountRouteData) {
        sync(with: route)

        switch route.editorKind {
        case .primary:
            primaryAmountEntryID = router?.currentEntryID(for: .sendMoneyAmount(route)) ?? primaryAmountEntryID

            guard let recipientEntryID else {
                router?.showErrorAlert("The flow lost the recipient bookmark.")
                return
            }

            let duplicateRoute = SendMoneyAmountRouteData(
                flowID: flowID,
                selectedRecipient: selectedRecipient,
                amount: duplicateAmount,
                recipientEntryID: recipientEntryID,
                editorKind: .duplicate
            )
            duplicateAmountEntryID = router?.showAmountEditor(duplicateRoute)

        case .duplicate:
            duplicateAmountEntryID = router?.currentEntryID(for: .sendMoneyAmount(route)) ?? duplicateAmountEntryID

            guard
                let recipientEntryID,
                let primaryAmountEntryID,
                let duplicateAmountEntryID
            else {
                router?.showErrorAlert("The flow needs all three bookmarks before it can build the review step.")
                return
            }

            let reviewRoute = SendMoneyReviewRouteData(
                flowID: flowID,
                selectedRecipient: selectedRecipient,
                primaryAmount: primaryAmount,
                duplicateAmount: duplicateAmount,
                recipientEntryID: recipientEntryID,
                primaryAmountEntryID: primaryAmountEntryID,
                duplicateAmountEntryID: duplicateAmountEntryID
            )
            _ = router?.showReview(reviewRoute)
        }
    }

    func editRecipient(route: SendMoneyReviewRouteData) {
        sync(with: route)
        router?.popToEntry(route.recipientEntryID)
    }

    func editPrimaryAmount(route: SendMoneyReviewRouteData) {
        sync(with: route)
        router?.popToEntry(route.primaryAmountEntryID)
    }

    func editDuplicateAmount(route: SendMoneyReviewRouteData) {
        sync(with: route)
        router?.popToEntry(route.duplicateAmountEntryID)
    }

    func showProtectedReceipt(route: SendMoneyReviewRouteData) {
        sync(with: route)
        _ = router?.showProtectedReceipt(
            ProtectedReceiptRouteData(
                flowID: flowID,
                selectedRecipient: selectedRecipient,
                amount: primaryAmount,
                reference: "BZM-\(flowID.uuidString.prefix(6))"
            )
        )
    }

    func showProtectedProfile(route: SendMoneyReviewRouteData) {
        sync(with: route)
        _ = router?.showProtectedProfile(
            ProtectedProfileRouteData(
                profileID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
                displayName: selectedRecipient,
                subtitle: "This destination is protected to demonstrate deep-link login interception."
            )
        )
    }

    func discardDraft() {
        router?.showDiscardDraftConfirmation(flowID: flowID)
    }
}
