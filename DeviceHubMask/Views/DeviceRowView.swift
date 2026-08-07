import SwiftUI

struct DeviceRowView: View {
    @Bindable var model: AppModel
    let device: RemoteDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                    Text("\(device.connection) · \(device.sessionPhase?.rawValue ?? "disconnected")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusDot(active: device.isActive)
            }
            HStack(spacing: 10) {
                if !device.isPaired {
                    Button("Pair", systemImage: "checkmark.shield", action: { model.pair(device) })
                        .buttonStyle(.bordered)
                } else if device.isActive {
                    Button("Disconnect", systemImage: "xmark.circle", action: { model.disconnect(device) })
                        .buttonStyle(.bordered)
                } else {
                    Button("Connect", systemImage: "link", action: { model.connect(device) })
                        .buttonStyle(.borderedProminent)
                        .tint(DeviceHubDesign.accent)
                }
                if device.sessionPhase == .connected {
                    NavigationLink(value: device) {
                        Label("Control", systemImage: "play.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 6)
        .disabled(model.isBusy)
    }
}

private struct StatusDot: View {
    let active: Bool

    var body: some View {
        Label(active ? "Connected" : "Offline", systemImage: active ? "circle.fill" : "circle")
            .font(.subheadline)
            .foregroundStyle(active ? .green : .secondary)
            .labelStyle(.titleAndIcon)
    }
}
