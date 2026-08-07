import SwiftUI

struct ControlView: View {
    let api: DeviceHubAPI
    let device: RemoteDevice

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: RemoteControlSession
    @State private var isFullscreen = false
    @State private var isControlPanelPresented = true

    init(api: DeviceHubAPI, device: RemoteDevice) {
        self.api = api
        self.device = device
        _session = State(initialValue: RemoteControlSession(api: api, device: device))
    }

    var body: some View {
        VStack(spacing: 0) {
            ControlStatusBar(session: session)
                .frame(maxHeight: isFullscreen ? 0 : nil)
                .opacity(isFullscreen ? 0 : 1)
                .clipped()
                .accessibilityHidden(isFullscreen)

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
            .clipShape(.rect(cornerRadius: isFullscreen ? 0 : DeviceHubDesign.cornerRadius))
            .padding(.horizontal, isFullscreen ? 0 : 12)
            .overlay(alignment: .bottomTrailing) {
                if session.videoFrameCount == 0, session.socketState == .connected {
                    ProgressView()
                        .tint(.white)
                        .padding(16)
                }
            }

            if !isFullscreen {
                controlPanel
            }
        }
        .background(.black)
        .ignoresSafeArea(.container, edges: isFullscreen ? .all : [])
        .overlay(alignment: .bottom) {
            if isFullscreen, isControlPanelPresented {
                controlPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isFullscreen, !isControlPanelPresented {
                Button("Show Controls", systemImage: "slider.horizontal.3", action: showControlPanel)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.black.opacity(0.72))
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(12)
                    .help("Show Controls")
                    .transition(.opacity)
            }
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(isFullscreen ? .hidden : .visible, for: .navigationBar)
        .statusBarHidden(isFullscreen)
        .onAppear(perform: session.start)
        .onDisappear(perform: session.stop)
        .onChange(of: scenePhase, handleScenePhase)
    }

    private var controlPanel: some View {
        DeviceControlPanel(
            session: session,
            isFullscreen: isFullscreen,
            toggleFullscreen: toggleFullscreen,
            dismiss: hideControlPanel
        )
    }

    private var connectionOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text(session.socketState == .failed ? "Connection Failed" : "Connecting")
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

    private func toggleFullscreen() {
        updateInterface {
            isFullscreen.toggle()
            isControlPanelPresented = !isFullscreen
        }
    }

    private func showControlPanel() {
        updateInterface {
            isControlPanelPresented = true
        }
    }

    private func hideControlPanel() {
        updateInterface {
            isControlPanelPresented = false
        }
    }

    private func updateInterface(_ changes: () -> Void) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(.snappy, changes)
        }
    }

    private func handleScenePhase(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            session.resumeMedia()
        case .background:
            session.pauseVideo()
        default:
            break
        }
    }
}
