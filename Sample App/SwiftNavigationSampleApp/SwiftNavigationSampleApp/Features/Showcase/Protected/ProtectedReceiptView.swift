import SwiftUI

struct ProtectedReceiptView: View {
    let route: ProtectedReceiptRouteData

    var body: some View {
        List {
            Section("Receipt") {
                Label(route.selectedRecipient, systemImage: "person.crop.circle")
                Text(route.amount, format: .currency(code: "EUR"))
                Text(route.reference)
                    .foregroundStyle(.secondary)
            }

            Section("Why this matters") {
                Text("This route is protected by the deeplink interceptor. When the session is expired, the library presents login first and then resumes this destination.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Protected Receipt")
    }
}
