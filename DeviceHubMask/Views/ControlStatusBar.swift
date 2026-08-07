import SwiftUI

struct ControlStatusBar: View {
    let session: RemoteControlSession

    var body: some View {
        HStack(spacing: 12) {
            Label(
                session.controlGranted ? "Control" : "View Only",
                systemImage: session.controlGranted ? "hand.tap.fill" : "eye"
            )
            .foregroundStyle(session.controlGranted ? .green : .orange)
            .help(session.controlGranted ? "Control Available" : "Another Client Has Control")

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
}
