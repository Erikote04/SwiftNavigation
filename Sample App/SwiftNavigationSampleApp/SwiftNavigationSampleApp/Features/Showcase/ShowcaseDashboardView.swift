import SwiftUI

@MainActor
struct ShowcaseDashboardView: View {
    let viewModel: ShowcaseDashboardViewModel
    let sessionStore: SessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ShowcaseHeroCard(
                    title: "SwiftNavigation v2",
                    subtitle: "Flow bookmarks, sheet presentation, typed alerts, and login interception in one place.",
                    authenticationLabel: viewModel.authenticationLabel,
                    isAuthenticated: sessionStore.isAuthenticated,
                    actionTitle: sessionStore.isAuthenticated ? "Expire Session" : "Sign In Demo User",
                    action: viewModel.toggleSession
                )

                ShowcaseCard(
                    title: "Flow Bookmarks",
                    subtitle: "The review step can jump back to the exact recipient or amount editor, even when the amount screen appears twice."
                ) {
                    Button("Start send money flow", systemImage: "arrow.trianglehead.branch") {
                        viewModel.startSendMoneyFlow()
                    }
                    .buttonStyle(.borderedProminent)
                }

                ShowcaseCard(
                    title: "Sheet Presentation",
                    subtitle: "Material and clear backgrounds, detents, background interaction, and one locked login sheet."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Open material sheet", systemImage: "square.stack.3d.up.fill") {
                            viewModel.showMaterialSheet()
                        }

                        Button("Open clear sheet", systemImage: "rectangle.transparent") {
                            viewModel.showClearSheet()
                        }

                        Button("Open locked login sheet", systemImage: "lock.shield") {
                            viewModel.showProtectedLoginSheet()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                ShowcaseCard(
                    title: "Coordinator Alerts",
                    subtitle: "Alerts can be triggered from the root tab or from a modal without local alert state in the views."
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Trigger root error alert", systemImage: "exclamationmark.triangle") {
                            viewModel.showRootErrorAlert()
                        }

                        Button("Open modal alert demo", systemImage: "rectangle.on.rectangle") {
                            viewModel.showAlertModal()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deep links")
                        .font(.headline)
                    Text("Try `swiftnavsample://showcase/profile` or `https://demo.swiftnavigation.app/showcase/receipt?recipient=Sonia&amount=35`.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct ShowcaseHeroCard: View {
    let title: String
    let subtitle: String
    let authenticationLabel: String
    let isAuthenticated: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isAuthenticated ? "checkmark.shield.fill" : "lock.slash")
                    .font(.title2)
                    .foregroundStyle(isAuthenticated ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .bold()
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Label(authenticationLabel, systemImage: isAuthenticated ? "person.crop.circle.badge.checkmark" : "clock.badge.xmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct ShowcaseCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}
