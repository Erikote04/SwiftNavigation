import SwiftUI

struct LocationDetailView: View {
    @State private var viewModel: LocationDetailViewModel

    init(route: LocationRouteData, service: RickMortyService, router: any LocationsRouting) {
        _viewModel = State(initialValue: LocationDetailViewModel(route: route, service: service, router: router))
    }

    var body: some View {
        List {
            Text(viewModel.route.name)
                .font(.headline)

            Label(viewModel.route.type, systemImage: "mappin.and.ellipse")
            Label(viewModel.route.dimension, systemImage: "globe")

            if let location = viewModel.location {
                Label("\(location.residents.count) residents", systemImage: "person.3")
            }

            Button("Show About (sheet)") {
                viewModel.didTapAbout()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading location...")
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert(
            "Request Failed",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
