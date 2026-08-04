import Foundation

public struct DiscoveredServer: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let host: String
    public let port: Int
    public let transport: String

    public init(id: String, name: String, host: String, port: Int, transport: String) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.transport = transport
    }

    public var origin: String {
        "http://\(host):\(port)"
    }
}
