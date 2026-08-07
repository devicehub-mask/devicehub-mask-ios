import SwiftUI

struct NearbyServersSection: View {
    @Bindable var model: AppModel

    var body: some View {
        Section {
            if let errorMessage = model.discovery.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if model.discovery.servers.isEmpty {
                Label("No Nearby Servers", systemImage: "network.slash")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.discovery.servers) { server in
                    Button {
                        model.use(server)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(server.name)
                                    .foregroundStyle(.primary)
                                Text(server.origin)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "server.rack")
                                .foregroundStyle(DeviceHubDesign.accent)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            HStack {
                Text("Nearby Servers")
                Spacer()
                Button(
                    model.discovery.isScanning ? "Stop Scanning" : "Scan for Servers",
                    systemImage: model.discovery.isScanning ? "stop.circle" : "dot.radiowaves.left.and.right",
                    action: toggleDiscovery
                )
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }

    private func toggleDiscovery() {
        model.setDiscoveryEnabled(!model.discovery.isScanning)
    }
}
