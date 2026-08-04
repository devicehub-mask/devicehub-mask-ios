import SwiftUI

struct ControlView: View {
    let api: DeviceHubAPI
    let device: RemoteDevice
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: RemoteControlSession

    init(api: DeviceHubAPI, device: RemoteDevice) {
        self.api = api
        self.device = device
        _session = State(initialValue: RemoteControlSession(api: api, device: device))
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            ZStack {
                DeviceHubVideoSurface(controller: session.media, orientation: session.orientation)
                DeviceHubTouchSurface(
                    enabled: session.controlGranted,
                    video: session.videoSize,
                    orientation: session.orientation,
                    onContacts: session.sendTouches
                )
                if session.socketState != .connected {
                    connectionOverlay
                }
            }
            .background(.black)
            .clipShape(.rect(cornerRadius: DeviceHubDesign.cornerRadius))
            .padding(.horizontal, 12)
            .overlay(alignment: .bottomTrailing) {
                if session.videoFrameCount == 0, session.socketState == .connected {
                    ProgressView()
                        .tint(.white)
                        .padding(16)
                }
            }
            controls
        }
        .background(.black)
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: session.start)
        .onDisappear(perform: session.stop)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                session.resumeMedia()
            case .background:
                session.pauseVideo()
            default:
                break
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label(
                session.controlGranted ? "Control" : "View only",
                systemImage: session.controlGranted ? "hand.tap.fill" : "eye"
            )
            .foregroundStyle(session.controlGranted ? .green : .orange)
            Spacer()
            if let size = session.videoSize {
                Text("\(Int(size.width)) × \(Int(size.height))")
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

    private var connectionOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text(session.socketState == .failed ? "Connection failed" : "Connecting")
                .font(.headline)
            if let message = session.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(.black.opacity(0.78))
        .clipShape(.rect(cornerRadius: DeviceHubDesign.cornerRadius))
        .padding(24)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ControlButton("Home", systemImage: "house.fill", enabled: session.controlGranted) {
                    session.pressButton("home")
                }
                ControlButton("Lock", systemImage: "lock.fill", enabled: session.controlGranted) {
                    session.pressButton("lock")
                }
                ControlButton("Rotate left", systemImage: "rotate.left", enabled: session.controlGranted) {
                    session.rotate(.left)
                }
                ControlButton("Rotate right", systemImage: "rotate.right", enabled: session.controlGranted) {
                    session.rotate(.right)
                }
            }
            if let metrics = session.streamMetrics {
                Text("\(metrics.sentFPS, format: .number.precision(.fractionLength(1))) fps · \(metrics.megabitsPerSecond, format: .number.precision(.fractionLength(1))) Mbps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.black)
    }
}

private struct ControlButton: View {
    let title: String
    let systemImage: String
    let enabled: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .tint(.white)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(!enabled)
            .accessibilityLabel(title)
    }
}
