import Foundation
import Observation

@MainActor
@Observable
final class RemoteControlSession {
    let media = DeviceHubMediaController()
    let device: RemoteDevice

    private(set) var socketState: SocketState = .disconnected
    private(set) var controlGranted = false
    private(set) var serverHello: ServerHello?
    private(set) var orientation: Orientation = .portrait
    private(set) var videoSize: VideoFrameSize?
    private(set) var videoFrameCount = 0
    private(set) var audioFormat = ""
    private(set) var streamMetrics: StreamMetrics?
    var errorMessage: String?

    private let socket: DeviceHubWebSocket

    init(api: DeviceHubAPI, device: RemoteDevice) {
        self.device = device
        socket = DeviceHubWebSocket(profile: api.profile, deviceID: device.id)
        socket.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    func start() {
        socket.start()
    }

    func stop() {
        socket.send(.videoDemand(active: false))
        socket.send(.audioDemand(active: false))
        socket.stop()
        media.reset()
    }

    func sendTouches(_ contacts: [MultiTouchContact]) {
        guard controlGranted else { return }
        socket.send(.multiTouch(contacts: contacts))
    }

    func pressButton(_ name: String) {
        guard controlGranted else { return }
        socket.send(.button(name: name))
    }

    func rotate(_ direction: DeviceHubCommand.RotationDirection) {
        guard controlGranted else { return }
        socket.send(.rotate(direction: direction))
    }

    func pauseVideo() {
        socket.send(.videoDemand(active: false))
    }

    func resumeMedia() {
        guard socketState == .connected else { return }
        socket.send(.videoDemand(active: true))
        socket.send(.audioDemand(active: true))
    }

    private func handle(_ event: DeviceHubSocketEvent) {
        switch event {
        case .opened:
            socketState = .connecting
        case .serverHello(let hello):
            serverHello = hello
            socketState = .connected
            resumeMedia()
        case .controlLease(let granted):
            controlGranted = granted
        case .status(let status):
            orientation = status.orientation
            media.update(orientation: status.orientation)
        case .video(let packet):
            videoSize = VideoFrameSize(width: Double(packet.width), height: Double(packet.height))
            videoFrameCount += 1
            if media.receive(packet) {
                socket.acknowledgeVideo(sequence: packet.sequence)
            } else {
                socket.requestVideoKeyframe()
            }
        case .audio(let packet):
            audioFormat = "\(packet.sampleRate) Hz / \(packet.channels) ch"
            media.receive(packet)
        case .clipboard, .deviceEvent:
            break
        case .metrics(let metrics):
            streamMetrics = metrics
        case .failed(let message):
            errorMessage = message
            socketState = .failed
        case .disconnected(let message):
            if let message, !message.isEmpty {
                errorMessage = message
            }
            controlGranted = false
            socketState = .disconnected
        }
    }
}
