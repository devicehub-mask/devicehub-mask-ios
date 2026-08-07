import SwiftUI

struct ControlStatusBar: View {
    let session: RemoteControlSession

    var body: some View {
        HStack(spacing: 12) {
            Label(
                statusTitle,
                systemImage: statusSystemImage
            )
            .foregroundStyle(statusColor)
            .help(statusHelp)

            Spacer()

            if let size = session.videoSize {
                Text("\(Int(size.width)) x \(Int(size.height))")
                    .monospacedDigit()
            }

            if !session.audioFormat.isEmpty {
                Label(session.audioFormat, systemImage: "speaker.wave.2")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black)
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
