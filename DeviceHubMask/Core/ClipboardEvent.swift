import Foundation

public struct ClipboardEvent: Codable, Sendable {
    public let fromDevice: Bool
    public let kind: String
    public let preview: String

    private enum CodingKeys: String, CodingKey {
        case fromDevice = "from_device"
        case kind
        case preview
    }
}
