import SwiftUI
import SwiftNavigation

struct CharacterActionsModalView: View {
    let character: CharacterRouteData

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        List {
            Section("Character") {
                Text(character.name)
                Text("\(character.species) • \(character.status)")
                    .foregroundStyle(.secondary)
            }

            Section("Navigation inside this modal") {
                NavigationLink(value: AppModalRoute.characterEpisodes(character)) {
                    Label("Browse episodes", systemImage: "list.bullet.rectangle")
                }
            }

            Section("Nested modal demo") {
                Button {
                    coordinator.present(.favoritesPlanner(character), style: .fullScreen)
                } label: {
                    Label("Open Favorites Planner (full screen)", systemImage: "rectangle.inset.filled.and.person.filled")
                }
            }

            Section {
                Button("Dismiss", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Character Actions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
