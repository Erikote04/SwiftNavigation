import SwiftUI

struct SheetShowcaseModalView: View {
    let route: SheetShowcaseRouteData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: route.systemImage)
                .font(.system(size: 36))
                .foregroundStyle(route.variant == .material ? .blue : .teal)

            VStack(alignment: .leading, spacing: 8) {
                Text(route.title)
                    .font(.title2)
                    .bold()
                Text(route.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(route.details)
                .font(.body)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
