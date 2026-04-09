import SwiftUI

struct ProtectedProfileView: View {
    let route: ProtectedProfileRouteData

    var body: some View {
        List {
            Section("Profile") {
                Text(route.displayName)
                    .font(.title3)
                    .bold()
                Text(route.subtitle)
                    .foregroundStyle(.secondary)
            }

            Section("Universal link demo") {
                Text("This screen can be opened from both a custom URL scheme and an HTTPS universal link.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Protected Profile")
    }
}
