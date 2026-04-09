import SwiftUI

@MainActor
struct LoginModalView: View {
    let route: LoginRouteData
    let sessionStore: SessionStore
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 8) {
                Text(route.title)
                    .font(.title2)
                    .bold()
                Text(route.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label("Source: \(route.source)", systemImage: "link")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Button("Sign in as \(sessionStore.isAuthenticated ? sessionStore.currentDisplayName : "Sonia")", systemImage: "person.badge.key") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)

                if !route.isDismissDisabled {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(24)
    }
}
