import SwiftUI

struct AlertShowcaseModalView: View {
    let onShowErrorAlert: () -> Void
    let onShowDiscardAlert: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Modal alert demo")
                    .font(.title2)
                    .bold()
                Text("This modal triggers root-managed alerts without owning any `@State` booleans for alert presentation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Button("Trigger modal error alert", systemImage: "exclamationmark.triangle") {
                    onShowErrorAlert()
                }
                .buttonStyle(.borderedProminent)

                Button("Trigger discard confirmation", systemImage: "trash") {
                    onShowDiscardAlert()
                }
                .buttonStyle(.bordered)
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }
}
