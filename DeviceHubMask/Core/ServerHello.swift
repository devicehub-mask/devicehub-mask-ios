import Foundation

public struct StreamAdvertisement: Codable, Equatable, Sendable {
    public let codec: String
    public let packet: String

    public init(codec: String, packet: String) {
        self.codec = codec
        self.packet = packet
    }
}

public struct ServerHello: Codable, Equatable, Sendable {
    public let protocolVersion: Int
    public let targetPlatforms: [String]
    public let video: StreamAdvertisement
    public let audio: StreamAdvertisement
    public let input: [String]
    public let controlLease: Bool

    public init(
        protocolVersion: Int,
        targetPlatforms: [String],
        video: StreamAdvertisement,
        audio: StreamAdvertisement,
        input: [String],
        controlLease: Bool
    ) {
        self.protocolVersion = protocolVersion
        self.targetPlatforms = targetPlatforms
        self.video = video
        self.audio = audio
        self.input = input
        self.controlLease = controlLease
    }

    public func validated() throws -> ServerHello {
        guard protocolVersion == 1 else {
            throw DeviceHubError.unsupportedProtocol(protocolVersion)
        }
        guard targetPlatforms.contains("ios") else {
            throw DeviceHubError.protocolViolation("The server does not advertise iPhone/iPad targets.")
        }
        guard video.codec == "hevc", video.packet == "DHV2" else {
            throw DeviceHubError.unsupportedVideoStream
        }
        guard audio.codec == "pcm_s16le", audio.packet == "DHA1" else {
            throw DeviceHubError.unsupportedAudioStream
        }
        guard input.contains("multi_touch") else {
            throw DeviceHubError.unsupportedInput
        }
        return self
    }

    private enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case targetPlatforms = "target_platforms"
        case video
        case audio
        case input
        case controlLease = "control_lease"
    }
}
