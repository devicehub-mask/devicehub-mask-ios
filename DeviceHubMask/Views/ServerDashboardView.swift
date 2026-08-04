import SwiftUI

struct ServerDashboardView: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Server") {
                    LabeledContent("Address", value: model.api?.profile.origin ?? "")
                    LabeledContent("Status", value: model.status?.status ?? "Unknown")
                }
                Section("Devices") {
                    if let status = model.status, !status.devices.isEmpty {
                        ForEach(status.devices) { device in
                            DeviceRowView(model: model, device: device)
                        }
                    } else {
                        ContentUnavailableView("No devices", systemImage: "iphone.slash")
                    }
                }
                if let errorMessage = model.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                }
            }
            .refreshable {
                await model.refresh()
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Disconnect", systemImage: "rectangle.portrait.and.arrow.right", action: model.disconnectServer)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh", systemImage: "arrow.clockwise", action: { Task { await model.refresh() } })
                }
            }
            .navigationDestination(for: RemoteDevice.self) { device in
                if let api = model.api {
                    ControlView(api: api, device: device)
                } else {
                    ContentUnavailableView("Server disconnected", systemImage: "network.slash")
                }
            }
        }
    }
}
