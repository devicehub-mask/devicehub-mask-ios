import Foundation

public enum DeviceHubError: Error, LocalizedError, Sendable, Equatable {
    case invalidServerAddress
    case missingAccessToken
    case unsupportedServerScheme
    case unsupportedProtocol(Int)
    case unsupportedVideoStream
    case unsupportedAudioStream
    case unsupportedInput
    case invalidMediaPacket(String)
    case http(status: Int, message: String)
    case requestTimedOut(String)
    case connectionClosed(String)
    case protocolViolation(String)

    public var errorDescription: String? {
        switch self {
        case .invalidServerAddress:
            "Enter a valid server address."
        case .missingAccessToken:
            "An access token is required."
        case .unsupportedServerScheme:
            "The server address must use http or https."
        case .unsupportedProtocol(let version):
            "Unsupported DeviceHub protocol version: \(version)."
        case .unsupportedVideoStream:
            "The server did not advertise the native HEVC stream."
        case .unsupportedAudioStream:
            "The server did not advertise the PCM audio stream."
        case .unsupportedInput:
            "The server did not advertise multi-touch input."
        case .invalidMediaPacket(let detail):
            "Invalid media packet: \(detail)"
        case .http(let status, let message):
            "Server request failed (\(status)): \(message)"
        case .requestTimedOut(let path):
            "The request timed out: \(path)"
        case .connectionClosed(let detail):
            detail.isEmpty ? "The remote connection closed." : detail
        case .protocolViolation(let detail):
            detail
        }
    }
}
