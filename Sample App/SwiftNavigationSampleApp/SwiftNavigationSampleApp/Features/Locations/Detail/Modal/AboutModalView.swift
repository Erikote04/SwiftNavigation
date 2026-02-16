import SwiftUI

struct AboutModalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SwiftNavigation Demo")
                .font(.title3.bold())

            Text("This sample app demonstrates tab navigation, push/pop, popToRoot, modal flows, internal modal navigation, and nested modals.")
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(24)
        .navigationTitle("About")
    }
}
