import SwiftUI

struct DeviceControlPanel: View {
    let session: RemoteControlSession
    let isFullscreen: Bool
    let toggleFullscreen: () -> Void
    let dismiss: () -> Void
    @AppStorage(AppSettingKey.showStreamMetrics) private var showStreamMetrics = true

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Label(
                    statusTitle,
                    systemImage: statusSystemImage
                )
                .foregroundStyle(statusColor)
                .layoutPriority(1)
                .help(statusHelp)

                if let metrics = session.streamMetrics, !isFullscreen, showStreamMetrics {
                    Text("\(metrics.sentFPS, format: .number.precision(.fractionLength(1))) fps / \(metrics.megabitsPerSecond, format: .number.precision(.fractionLength(1))) Mbps")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                Button(
                    isFullscreen ? "Exit Full Screen" : "Enter Full Screen",
                    systemImage: isFullscreen
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right",
                    action: toggleFullscreen
                )
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .frame(minWidth: 44, minHeight: 44)
                .help(isFullscreen ? "Exit Full Screen" : "Enter Full Screen")

                if isFullscreen {
                    Button("Hide Controls", systemImage: "chevron.down", action: dismiss)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .frame(minWidth: 44, minHeight: 44)
                        .help("Hide Controls")
                }
            }
            .font(.caption)

            if session.socketState == .connected, !session.controlGranted {
                Label("Another client has control", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(DeviceControlAction.allCases) { action in
                    DeviceControlButton(
                        action: action,
                        isEnabled: session.supports(action),
                        perform: session.perform
                    )
                }
            }
        }
        .padding(12)
        .background {
            if isFullscreen {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                Color.black
            }
        }
    }

    private var statusTitle: String {
        guard session.socketState == .connected else { return "Connecting" }
        return session.controlGranted ? "Control" : "View Only"
    }

    private var statusSystemImage: String {
        guard session.socketState == .connected else { return "network" }
        return session.controlGranted ? "hand.tap.fill" : "eye"
    }

    private var statusColor: Color {
        guard session.socketState == .connected else { return .secondary }
        return session.controlGranted ? .green : .orange
    }

    private var statusHelp: String {
        guard session.socketState == .connected else { return "Connecting to DeviceHub Mask" }
        return session.controlGranted ? "Control Available" : "Another Client Has Control"
    }
}
