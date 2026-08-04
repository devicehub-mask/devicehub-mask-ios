import Foundation

public enum SessionPhase: String, Codable, Sendable, Equatable {
    case discovered
    case connecting
    case connected
    case recovering
    case disconnecting
    case disconnected
    case failed
    case unknown

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = SessionPhase(rawValue: value) ?? .unknown
    }
}
