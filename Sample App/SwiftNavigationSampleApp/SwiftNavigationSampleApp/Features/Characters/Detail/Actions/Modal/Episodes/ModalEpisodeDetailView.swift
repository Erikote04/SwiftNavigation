import SwiftUI

struct ModalEpisodeDetailView: View {
    let route: EpisodeRouteData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Text(route.name)
                .font(.headline)
            Label(route.code, systemImage: "tv")
            Label(route.airDate, systemImage: "calendar")

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Episode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
