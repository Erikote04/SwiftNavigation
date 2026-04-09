import SwiftUI

@MainActor
struct SendMoneyAmountView: View {
    let route: SendMoneyAmountRouteData
    let viewModel: SendMoneyFlowViewModel

    init(route: SendMoneyAmountRouteData, viewModel: SendMoneyFlowViewModel) {
        self.route = route
        self.viewModel = viewModel
        viewModel.sync(with: route)
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.editorKind.title)
                        .font(.title2)
                        .bold()
                    Text("The flow intentionally opens this editor twice. Each presentation gets a unique `NavigationEntryID` even though the screen type is the same.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recipient")
                        .font(.headline)
                    Text(viewModel.selectedRecipient)
                        .font(.title3)
                        .bold()
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    Text(currentAmount, format: .currency(code: "EUR"))
                        .font(.system(size: 42, weight: .light, design: .rounded))

                    Stepper(value: amountBinding, in: 5 ... 250, step: 5) {
                        Text("Adjust in 5€ steps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: amountBinding, in: 5 ... 250, step: 5)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))

                Button(nextButtonTitle, systemImage: nextButtonImage) {
                    bindableViewModel.continueFromAmount(route: route)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.editorKind == .primary ? "Amount" : "Amount Copy")
    }

    private var currentAmount: Double {
        route.editorKind == .primary ? viewModel.primaryAmount : viewModel.duplicateAmount
    }

    private var amountBinding: Binding<Double> {
        Binding(
            get: { currentAmount },
            set: { newValue in
                switch route.editorKind {
                case .primary:
                    viewModel.primaryAmount = newValue
                case .duplicate:
                    viewModel.duplicateAmount = newValue
                }
            }
        )
    }

    private var nextButtonTitle: String {
        switch route.editorKind {
        case .primary:
            "Add duplicate editor"
        case .duplicate:
            "Review payment"
        }
    }

    private var nextButtonImage: String {
        switch route.editorKind {
        case .primary:
            "square.stack.3d.up"
        case .duplicate:
            "text.magnifyingglass"
        }
    }
}
