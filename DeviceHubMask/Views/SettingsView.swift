import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingKey.automaticallyDiscoverServers) private var automaticallyDiscoverServers = true
    @AppStorage(AppSettingKey.automaticallyConnectLastServer) private var automaticallyConnectLastServer = false
    @AppStorage(AppSettingKey.deviceAudioEnabled) private var deviceAudioEnabled = true
    @AppStorage(AppSettingKey.showStreamMetrics) private var showStreamMetrics = true
    @State private var isConfirmingHistoryClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    Toggle("Discover Nearby Servers Automatically", systemImage: "dot.radiowaves.left.and.right", isOn: $automaticallyDiscoverServers)
                    Toggle("Connect to Last Server Automatically", systemImage: "bolt.horizontal.circle", isOn: $automaticallyConnectLastServer)
                }

                Section("Remote Control") {
                    Toggle("Play Device Audio", systemImage: "speaker.wave.2", isOn: $deviceAudioEnabled)
                    Toggle("Show Stream Metrics", systemImage: "gauge.with.dots.needle.67percent", isOn: $showStreamMetrics)
                }

                Section("Connection History") {
                    LabeledContent("Saved Servers", value: model.connectionHistory.servers.count, format: .number)
                    Button("Clear Connection History", systemImage: "trash", role: .destructive, action: confirmHistoryClear)
                        .disabled(model.connectionHistory.servers.isEmpty)
                        .confirmationDialog(
                            "Clear Connection History?",
                            isPresented: $isConfirmingHistoryClear,
                            titleVisibility: .visible
                        ) {
                            Button("Clear History", role: .destructive, action: model.clearConnectionHistory)
                        } message: {
                            Text("Saved server addresses and access tokens will be removed from this device.")
                        }
                }

                Section {
                    NavigationLink("About DeviceHub Mask", value: SettingsDestination.about)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .about:
                    AboutView()
                }
            }
            .onChange(of: automaticallyDiscoverServers) { _, enabled in
                model.setDiscoveryEnabled(enabled)
            }
        }
    }

    private func confirmHistoryClear() {
        isConfirmingHistoryClear = true
    }
}
