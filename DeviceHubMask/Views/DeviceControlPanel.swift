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
                    session.controlGranted ? "Control" : "View Only",
                    systemImage: session.controlGranted ? "hand.tap.fill" : "eye"
                )
                .foregroundStyle(session.controlGranted ? .green : .orange)
                .layoutPriority(1)
                .help(session.controlGranted ? "Control Available" : "Another Client Has Control")

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
}
