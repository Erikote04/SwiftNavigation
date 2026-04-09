import Observation

@MainActor
@Observable
final class SessionStore {
    var isAuthenticated = false
    var currentDisplayName = "Guest"

    func signInDemoUser() {
        isAuthenticated = true
        currentDisplayName = "Sonia"
    }

    func expireSession() {
        isAuthenticated = false
        currentDisplayName = "Guest"
    }
}
