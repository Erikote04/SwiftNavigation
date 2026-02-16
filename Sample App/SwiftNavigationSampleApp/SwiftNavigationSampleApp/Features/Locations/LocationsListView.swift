import SwiftUI

struct LocationsListView: View {
    let viewModel: LocationsListViewModel

    var body: some View {
        List(viewModel.locations) { location in
            Button {
                viewModel.didTapLocation(location)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                    Text("\(location.type) • \(location.dimension)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading locations...")
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings") {
                    viewModel.didTapSettings()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
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
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}


