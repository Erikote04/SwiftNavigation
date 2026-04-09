import SwiftUI

@MainActor
struct SendMoneyReviewView: View {
    let route: SendMoneyReviewRouteData
    let viewModel: SendMoneyFlowViewModel

    init(route: SendMoneyReviewRouteData, viewModel: SendMoneyFlowViewModel) {
        self.route = route
        self.viewModel = viewModel
        viewModel.sync(with: route)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review payment")
                        .font(.title2)
                        .bold()
                    Text("Each edit button jumps to a bookmarked stack entry instead of just “the last matching route”.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    reviewRow(title: "Recipient", value: route.selectedRecipient) {
                        viewModel.editRecipient(route: route)
                    }
                    reviewRow(title: "Primary amount", value: route.primaryAmount.formatted(.currency(code: "EUR"))) {
                        viewModel.editPrimaryAmount(route: route)
                    }
                    reviewRow(title: "Duplicate amount", value: route.duplicateAmount.formatted(.currency(code: "EUR"))) {
                        viewModel.editDuplicateAmount(route: route)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Button("Open protected receipt", systemImage: "lock.open.display") {
                        viewModel.showProtectedReceipt(route: route)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open protected profile", systemImage: "person.crop.rectangle.stack") {
                        viewModel.showProtectedProfile(route: route)
                    }
                    .buttonStyle(.bordered)

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
        .navigationTitle("Review")
    }

    private func reviewRow(
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            HStack {
                Text(value)
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Edit", action: action)
            }
        }
    }
}
