import Foundation

@MainActor
public final class DeviceHubWebSocket {
    public var onEvent: (@MainActor @Sendable (DeviceHubSocketEvent) -> Void)?
    public private(set) var state: SocketState = .disconnected

    private let profile: ConnectionProfile
    private let deviceID: String
    private let clientVersion: String
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var handshakeTask: Task<Void, Never>?
    private var isStopping = false

    public init(
        profile: ConnectionProfile,
        deviceID: String,
        clientVersion: String = "1.0.0"
    ) {
        self.profile = profile
        self.deviceID = deviceID
        self.clientVersion = clientVersion
        session = URLSession(configuration: .ephemeral)
    }

    deinit {
        receiveTask?.cancel()
        handshakeTask?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }

    public func start() {
        guard task == nil else { return }
        isStopping = false
        state = .connecting
        do {
            let url = try profile.websocketURL(deviceID: deviceID)
            let webSocket = session.webSocketTask(with: url, protocols: ["devicehub-mask", profile.token])
            task = webSocket
            webSocket.resume()
            receiveTask = Task { @MainActor [weak self] in
                guard let self, let webSocket = self.task else { return }
                do {
                    try await self.send(
                        .clientHello(
                            protocolVersion: 1,
                            platform: "ios",
                            clientVersion: self.clientVersion,
                            capabilities: ["native_hevc", "native_pcm", "multi_touch", "hardware_buttons"]
                        ),
                        using: webSocket
                    )
                    self.emit(.opened)
                    while !Task.isCancelled {
                        let message = try await webSocket.receive()
                        try self.handle(message)
                    }
                } catch is CancellationError {
                    if !self.isStopping {
                        self.finishFailure(DeviceHubError.connectionClosed("The WebSocket receive loop was cancelled."))
                    }
                } catch {
                    if !self.isStopping {
                        self.finishFailure(error)
                    }
                }
            }
            handshakeTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(for: .seconds(8))
                } catch {
                    return
                }
                guard let self, self.state == .connecting else { return }
                self.finishFailure(DeviceHubError.requestTimedOut("WebSocket handshake"))
            }
        } catch {
            finishFailure(error)
        }
    }

    public func stop() {
        guard task != nil || state != .disconnected else { return }
        isStopping = true
        receiveTask?.cancel()
        handshakeTask?.cancel()
        receiveTask = nil
        handshakeTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
        emit(.disconnected(nil))
    }

    public func send(_ command: DeviceHubCommand) {
        guard let task, state == .connected || state == .connecting else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.send(command, using: task)
            } catch {
                self.finishFailure(error)
            }
        }
    }

    public func acknowledgeVideo(sequence: UInt64) {
        send(.browserFrameAccepted(sequence: sequence))
    }

    public func requestVideoKeyframe() {
        send(.browserVideoKeyframe)
    }

    private func send(_ command: DeviceHubCommand, using task: URLSessionWebSocketTask) async throws {
        let data = try encoder.encode(command)
        guard let text = String(data: data, encoding: .utf8) else {
            throw DeviceHubError.protocolViolation("Unable to encode a WebSocket command.")
        }
        try await task.send(.string(text))
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) throws {
        switch message {
        case .data(let data):
            guard let packet = try MediaPacketParser.parse(data) else { return }
            switch packet {
            case .video(let video):
                emit(.video(video))
            case .audio(let audio):
                emit(.audio(audio))
            }
        case .string(let text):
            try handleText(Data(text.utf8))
        @unknown default:
            throw DeviceHubError.protocolViolation("The server sent an unknown WebSocket message.")
        }
    }

    private func handleText(_ data: Data) throws {
        let header = try decoder.decode(ServerMessageHeader.self, from: data)
        switch header.type {
        case "server_hello":
            let message = try decoder.decode(ServerEnvelope<ServerHello>.self, from: data)
            let hello = try message.payload.validated()
            handshakeTask?.cancel()
            handshakeTask = nil
            state = .connected
            emit(.serverHello(hello))
        case "control_lease":
            let message = try decoder.decode(ServerEnvelope<ControlLeasePayload>.self, from: data)
            emit(.controlLease(granted: message.payload.granted))
        case "status":
            let message = try decoder.decode(ServerEnvelope<DeviceStatusResponse>.self, from: data)
            emit(.status(message.payload))
        case "clipboard":
            let message = try decoder.decode(ServerEnvelope<ClipboardEvent>.self, from: data)
            emit(.clipboard(message.payload))
        case "device_event":
            let message = try decoder.decode(ServerEnvelope<DeviceEvent>.self, from: data)
            emit(.deviceEvent(message.payload))
        case "metrics", "stream_metrics":
            let message = try decoder.decode(ServerEnvelope<StreamMetrics>.self, from: data)
            emit(.metrics(message.payload))
        default:
            break
        }
    }

    private func finishFailure(_ error: Error) {
        guard !isStopping else { return }
        state = .failed
        let message = error.localizedDescription
        emit(.failed(message))
        task?.cancel(with: .protocolError, reason: nil)
        task = nil
        receiveTask?.cancel()
        receiveTask = nil
        handshakeTask?.cancel()
        handshakeTask = nil
        state = .disconnected
        emit(.disconnected(message))
    }

    private func emit(_ event: DeviceHubSocketEvent) {
        onEvent?(event)
    }
}

private struct ServerMessageHeader: Decodable {
    let type: String
}

private struct ServerEnvelope<Payload: Decodable>: Decodable {
    let payload: Payload
}

private struct ControlLeasePayload: Decodable {
    let granted: Bool
}
