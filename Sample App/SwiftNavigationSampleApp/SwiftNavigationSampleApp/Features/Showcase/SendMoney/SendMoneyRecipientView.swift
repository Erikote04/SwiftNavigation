import SwiftUI

@MainActor
struct SendMoneyRecipientView: View {
    let route: SendMoneyRecipientRouteData
    let viewModel: SendMoneyFlowViewModel

    init(route: SendMoneyRecipientRouteData, viewModel: SendMoneyFlowViewModel) {
        self.route = route
        self.viewModel = viewModel
        viewModel.sync(with: route)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a recipient")
                        .font(.title2)
                        .bold()
                    Text("This is the first bookmarked step in the flow. The review screen stores its entry ID so it can jump back here later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.availableRecipients, id: \.self) { recipient in
                        Button {
                            viewModel.selectedRecipient = recipient
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipient)
                                        .font(.headline)
                                    Text("Bizum contact")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if viewModel.selectedRecipient == recipient {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button("Continue", systemImage: "arrow.right.circle.fill") {
                        viewModel.continueFromRecipient(route: route)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Discard draft", systemImage: "trash") {
                        viewModel.discardDraft()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recipient")
    }
}
