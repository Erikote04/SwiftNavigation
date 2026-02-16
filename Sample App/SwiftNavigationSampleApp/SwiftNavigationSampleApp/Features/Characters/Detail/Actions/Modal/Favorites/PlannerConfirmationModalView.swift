import SwiftUI

struct PlannerConfirmationModalView: View {
    let character: CharacterRouteData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Plan created for \(character.name)")
                .font(.headline)
            Text("This is a nested sheet presented on top of a full-screen modal.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
