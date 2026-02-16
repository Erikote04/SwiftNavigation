import SwiftNavigation
import SwiftUI

struct SettingsModalView: View {
    @State private var notificationsEnabled = true

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator<AppRoute, AppModalRoute>.self) private var coordinator

    var body: some View {
        List {
            Section("Preferences") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            Section("Navigation in modal") {
                NavigationLink(value: AppModalRoute.about) {
                    Label("About (push)", systemImage: "info.circle")
                }

                Button {
                    coordinator.present(.about, style: .sheet)
                } label: {
                    Label("About (sheet)", systemImage: "doc.text.magnifyingglass")
                }
            }

            Section {
                Button("Close settings", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
