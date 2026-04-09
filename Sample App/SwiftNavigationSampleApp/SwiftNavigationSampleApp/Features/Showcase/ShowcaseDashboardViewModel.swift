import Observation

@MainActor
@Observable
final class ShowcaseDashboardViewModel {
    private weak var router: (any ShowcaseRouting)?
    private let sessionStore: SessionStore

    init(router: any ShowcaseRouting, sessionStore: SessionStore) {
        self.router = router
        self.sessionStore = sessionStore
    }

    var authenticationLabel: String {
        sessionStore.isAuthenticated ? "Authenticated as \(sessionStore.currentDisplayName)" : "Session expired"
    }

    func toggleSession() {
        if sessionStore.isAuthenticated {
            sessionStore.expireSession()
        } else {
            sessionStore.signInDemoUser()
        }
    }

    func startSendMoneyFlow() {
        router?.startSendMoneyFlow()
    }

    func showMaterialSheet() {
        router?.showMaterialSheetShowcase()
    }

    func showClearSheet() {
        router?.showClearSheetShowcase()
    }

    func showProtectedLoginSheet() {
        router?.showProtectedLoginSheet()
    }

    func showRootErrorAlert() {
        router?.showErrorAlert("Root-level actions can drive alerts without keeping local SwiftUI alert state.")
    }

    func showAlertModal() {
        router?.showAlertShowcaseModal()
    }
}
