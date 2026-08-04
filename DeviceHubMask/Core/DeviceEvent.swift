import Foundation

public struct DeviceEvent: Codable, Sendable {
    public let sequence: Int64
    public let kind: String
}
