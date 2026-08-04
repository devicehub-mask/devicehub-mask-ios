import Foundation

public struct PairDeviceResult: Codable, Sendable {
    public let outcome: String
    public let error: String?
}
