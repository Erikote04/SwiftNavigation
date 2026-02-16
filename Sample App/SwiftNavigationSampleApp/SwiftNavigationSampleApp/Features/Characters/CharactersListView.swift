import SwiftUI

struct CharactersListView: View {
    let viewModel: CharactersListViewModel

    var body: some View {
        List(viewModel.characters) { character in
            Button {
                viewModel.didTapCharacter(character)
            } label: {
                CharacterRowView(character: character)
            }
            .buttonStyle(.plain)
            .task {
                await viewModel.loadMoreIfNeeded(currentID: character.id)
            }

            if viewModel.isLoadingNextPage, character.id == viewModel.characters.last?.id {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .overlay {
            if viewModel.isInitialLoading {
                ProgressView("Loading characters...")
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadInitialIfNeeded()
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

private struct CharacterRowView: View {
    let character: CharacterRouteData

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: character.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                Text("\(character.species) • \(character.status)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
