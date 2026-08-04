import Foundation

public enum DeviceHubSocketEvent: Sendable {
    case opened
    case serverHello(ServerHello)
    case controlLease(granted: Bool)
    case status(DeviceStatusResponse)
    case clipboard(ClipboardEvent)
    case deviceEvent(DeviceEvent)
    case metrics(StreamMetrics)
    case video(VideoPacket)
    case audio(AudioPacket)
    case failed(String)
    case disconnected(String?)
}
