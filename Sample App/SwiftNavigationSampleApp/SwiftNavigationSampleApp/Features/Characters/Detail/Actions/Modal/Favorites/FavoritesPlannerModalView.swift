import SwiftNavigation
import SwiftUI

struct FavoritesPlannerModalView: View {
    let character: CharacterRouteData

    @State private var includeEpisodes = true
    @State private var includeLocation = true

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    Toggle("Include episodes", isOn: $includeEpisodes)
                    Toggle("Include location", isOn: $includeLocation)
                }

                Section("Flow demo") {
                    Button("Open confirmation (sheet over full screen)") {
                        coordinator.present(.plannerConfirmation(character), style: .sheet)
                    }
                }

                Section {
                    Button("Dismiss planner", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Favorites Planner")
        }
    }
}
