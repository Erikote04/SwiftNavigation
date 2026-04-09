import Foundation
import SwiftNavigation
import Testing
@testable import SwiftNavigationSampleApp

@Suite("SwiftNavigation Sample App Showcase")
@MainActor
struct ShowcaseSampleAppTests {
    @Test("Custom scheme deeplink opens the send money flow")
    func customSchemeDeepLinkParsesSendMoneyFlow() throws {
        let url = try #require(URL(string: "swiftnavsample://showcase/send-money?recipient=Sonia"))
        let preferredTab = try AppURLDeepLinkResolver.preferredRootTab(for: url)
        let state = try AppURLDeepLinkResolver().navigationState(for: url)

        #expect(preferredTab == .showcase)
        #expect(state.modalStack.isEmpty)

        let route = try #require(state.stack.first)
        switch route {
        case .sendMoneyRecipient(let routeData):
            #expect(routeData.selectedRecipient == "Sonia")
            #expect(routeData.availableRecipients.contains("Sonia"))
        default:
            Issue.record("Expected a send money recipient route for the custom scheme deeplink.")
        }
    }

    @Test("HTTPS deeplink resolves as a protected receipt")
    func universalLinkParsesProtectedReceipt() throws {
        let url = try #require(
            URL(string: "https://demo.swiftnavigation.app/showcase/receipt?recipient=Sonia&amount=35")
        )
        let preferredTab = try AppURLDeepLinkResolver.preferredRootTab(for: url)
        let state = try AppURLDeepLinkResolver().navigationState(for: url)

        #expect(preferredTab == .showcase)
        #expect(state.modalStack.isEmpty)

        let route = try #require(state.stack.first)
        switch route {
        case .protectedReceipt(let routeData):
            #expect(routeData.selectedRecipient == "Sonia")
            #expect(routeData.amount == 35)
            #expect(routeData.reference.localizedStandardContains("BZM"))
        default:
            Issue.record("Expected a protected receipt route for the HTTPS deeplink.")
        }
    }

    @Test("Protected deeplinks redirect to login and resume after sign in")
    func loginInterceptorRedirectsAndResumesPendingNavigation() async throws {
        UserDefaults.standard.removeObject(forKey: "swiftNavigationSample.navigationState.v2")
        UserDefaults.standard.removeObject(forKey: "swiftNavigationSample.selectedRootTab")

        let coordinator = AppCoordinator()
        coordinator.sessionStore.expireSession()

        let url = try #require(URL(string: "https://demo.swiftnavigation.app/showcase/profile?displayName=Sonia"))
        await coordinator.handleDeepLinkURL(url)

        let modal = try #require(coordinator.navigationCoordinator.modalStack.first)
        switch modal.root {
        case .login(let route):
            #expect(route.isDismissDisabled)
            #expect(route.source == "Deep link interceptor")
        default:
            Issue.record("Expected the deep link interceptor to present the login sheet.")
        }

        let pendingState = try #require(coordinator.navigationCoordinator.pendingNavigationState)
        let pendingRoute = try #require(pendingState.stack.first)
        switch pendingRoute {
        case .protectedProfile(let route):
            #expect(route.displayName == "Sonia")
        default:
            Issue.record("Expected the pending state to keep the protected profile destination.")
        }

        coordinator.completeLogin()

        #expect(coordinator.sessionStore.isAuthenticated)
        #expect(coordinator.navigationCoordinator.pendingNavigationState == nil)
        #expect(coordinator.navigationCoordinator.modalStack.isEmpty)

        let resumedRoute = try #require(coordinator.navigationCoordinator.stack.first)
        switch resumedRoute {
        case .protectedProfile(let route):
            #expect(route.displayName == "Sonia")
        default:
            Issue.record("Expected the protected profile destination to resume after login.")
        }
    }

    @Test("Send money flow stores entry bookmarks and reuses them from review")
    func sendMoneyFlowViewModelTracksExactEntryIDs() {
        let flowID = UUID()
        let recipientEntryID = NavigationEntryID()
        let primaryAmountEntryID = NavigationEntryID()
        let duplicateAmountEntryID = NavigationEntryID()
        let router = ShowcaseRoutingSpyingStub(
            nextAmountEntryIDs: [primaryAmountEntryID, duplicateAmountEntryID],
            nextReviewEntryID: NavigationEntryID()
        )
        let viewModel = SendMoneyFlowViewModel(
            flowID: flowID,
            router: router,
            selectedRecipient: "Sonia",
            availableRecipients: ["Sonia", "Alex", "Maya", "Taylor"],
            primaryAmount: 35,
            duplicateAmount: 48
        )

        let recipientRoute = SendMoneyRecipientRouteData(
            flowID: flowID,
            selectedRecipient: "Sonia",
            availableRecipients: ["Sonia", "Alex", "Maya", "Taylor"]
        )
        router.currentEntryIDs[.sendMoneyRecipient(recipientRoute)] = recipientEntryID

        viewModel.continueFromRecipient(route: recipientRoute)

        let firstAmountRoute = tryRequire(router.amountRoutes.first)
        #expect(firstAmountRoute.editorKind == .primary)
        #expect(firstAmountRoute.recipientEntryID == recipientEntryID)

        let primaryRoute = SendMoneyAmountRouteData(
            flowID: flowID,
            selectedRecipient: "Sonia",
            amount: 35,
            recipientEntryID: recipientEntryID,
            editorKind: .primary
        )
        router.currentEntryIDs[.sendMoneyAmount(primaryRoute)] = primaryAmountEntryID

        viewModel.continueFromAmount(route: primaryRoute)

        let duplicateRoute = tryRequire(router.amountRoutes.last)
        #expect(duplicateRoute.editorKind == .duplicate)
        #expect(duplicateRoute.recipientEntryID == recipientEntryID)

        let duplicateAmountRoute = SendMoneyAmountRouteData(
            flowID: flowID,
            selectedRecipient: "Sonia",
            amount: 48,
            recipientEntryID: recipientEntryID,
            editorKind: .duplicate
        )
        router.currentEntryIDs[.sendMoneyAmount(duplicateAmountRoute)] = duplicateAmountEntryID

        viewModel.continueFromAmount(route: duplicateAmountRoute)

        let reviewRoute = tryRequire(router.reviewRoutes.first)
        #expect(reviewRoute.recipientEntryID == recipientEntryID)
        #expect(reviewRoute.primaryAmountEntryID == primaryAmountEntryID)
        #expect(reviewRoute.duplicateAmountEntryID == duplicateAmountEntryID)

        viewModel.editPrimaryAmount(route: reviewRoute)
        viewModel.editDuplicateAmount(route: reviewRoute)

        #expect(router.poppedEntryIDs == [primaryAmountEntryID, duplicateAmountEntryID])
    }

    private func tryRequire<T>(_ value: T?) -> T {
        guard let value else {
            fatalError("Expected value to be present during the test.")
        }
        return value
    }
}

@MainActor
private final class ShowcaseRoutingSpyingStub: ShowcaseRouting {
    var currentEntryIDs: [AppRoute: NavigationEntryID] = [:]
    var amountRoutes: [SendMoneyAmountRouteData] = []
    var reviewRoutes: [SendMoneyReviewRouteData] = []
    var poppedEntryIDs: [NavigationEntryID] = []
    var errorMessages: [String] = []
    var discardedFlowIDs: [UUID] = []
    var nextAmountEntryIDs: [NavigationEntryID]
    var nextReviewEntryID: NavigationEntryID

    init(
        nextAmountEntryIDs: [NavigationEntryID],
        nextReviewEntryID: NavigationEntryID
    ) {
        self.nextAmountEntryIDs = nextAmountEntryIDs
        self.nextReviewEntryID = nextReviewEntryID
    }

    func startSendMoneyFlow() {}

    func showAmountEditor(_ route: SendMoneyAmountRouteData) -> NavigationEntryID {
        amountRoutes.append(route)
        guard !nextAmountEntryIDs.isEmpty else {
            return NavigationEntryID()
        }
        return nextAmountEntryIDs.removeFirst()
    }

    func showReview(_ route: SendMoneyReviewRouteData) -> NavigationEntryID {
        reviewRoutes.append(route)
        return nextReviewEntryID
    }

    func showProtectedReceipt(_ route: ProtectedReceiptRouteData) -> NavigationEntryID {
        NavigationEntryID()
    }

    func showProtectedProfile(_ route: ProtectedProfileRouteData) -> NavigationEntryID {
        NavigationEntryID()
    }

    func currentEntryID(for route: AppRoute) -> NavigationEntryID? {
        currentEntryIDs[route]
    }

    func popToEntry(_ id: NavigationEntryID) {
        poppedEntryIDs.append(id)
    }

    func popToRoot() {}

    func showMaterialSheetShowcase() {}

    func showClearSheetShowcase() {}

    func showProtectedLoginSheet() {}

    func showAlertShowcaseModal() {}

    func showErrorAlert(_ message: String) {
        errorMessages.append(message)
    }

    func showDiscardDraftConfirmation(flowID: UUID) {
        discardedFlowIDs.append(flowID)
    }

    func dismissTopModal() {}
}
