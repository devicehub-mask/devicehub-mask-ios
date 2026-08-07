import SwiftUI

struct SavedServerRowView: View {
    let server: SavedServer

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(server.displayName)
                    .foregroundStyle(.primary)
                Text(server.origin)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(server.lastConnectedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(DeviceHubDesign.accent)
        }
    }
}
