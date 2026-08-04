import Foundation

public struct DeviceResources: Codable, Hashable, Sendable {
    public let video: Bool
    public let audio: Bool
    public let performance: Bool
    public let deviceLogs: Bool

    public init(video: Bool, audio: Bool, performance: Bool, deviceLogs: Bool) {
        self.video = video
        self.audio = audio
        self.performance = performance
        self.deviceLogs = deviceLogs
    }

    private enum CodingKeys: String, CodingKey {
        case video
        case audio
        case performance
        case deviceLogs = "device_logs"
    }
}
