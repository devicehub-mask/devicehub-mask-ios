import SwiftUI

struct ConnectionView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DeviceHubDesign.sectionSpacing) {
                    HeaderView()
                    connectionForm
                    discoveredServers
                    if let errorMessage = model.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                }
                .padding(DeviceHubDesign.pagePadding)
            }
            .background(DeviceHubDesign.background)
            .navigationTitle("DeviceHub Mask")
        }
    }

    private var connectionForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remote server")
                .font(.headline)
            TextField("http://192.168.1.10:8080", text: $model.serverInput)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: DeviceHubDesign.controlHeight)
            SecureField("Access token", text: $model.tokenInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: DeviceHubDesign.controlHeight)
            Button("Connect", systemImage: "arrow.right.circle.fill", action: model.connect)
                .buttonStyle(.borderedProminent)
                .tint(DeviceHubDesign.accent)
                .frame(maxWidth: .infinity, minHeight: DeviceHubDesign.controlHeight)
                .disabled(model.isBusy)
        }
        .padding()
        .background(DeviceHubDesign.panel)
        .clipShape(.rect(cornerRadius: DeviceHubDesign.cornerRadius))
    }

    private var discoveredServers: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby servers")
                    .font(.headline)
                Spacer()
                Button(
                    model.discovery.isScanning ? "Stop" : "Scan",
                    systemImage: model.discovery.isScanning ? "stop.circle" : "dot.radiowaves.left.and.right",
                    action: toggleDiscovery
                )
                .labelStyle(.iconOnly)
                .accessibilityLabel(model.discovery.isScanning ? "Stop scanning" : "Scan for servers")
                .frame(minWidth: 44, minHeight: 44)
            }
            if model.discovery.servers.isEmpty {
                ContentUnavailableView(
                    "No servers found",
                    systemImage: "network.slash",
                    description: Text("Enter an address manually or start a headless server on the same network.")
                )
            } else {
                ForEach(model.discovery.servers) { server in
                    Button {
                        model.use(server)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func toggleDiscovery() {
        if model.discovery.isScanning {
            model.discovery.stop()
        } else {
            model.discovery.start()
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Headless remote control")
                .font(.title2.bold())
            Text("Connect to a DeviceHub Mask host to inspect and control iPhone or iPad sessions.")
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.red.opacity(0.1))
            .clipShape(.rect(cornerRadius: DeviceHubDesign.cornerRadius))
    }
}
