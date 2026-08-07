import Foundation

public struct ConnectionHistory: Codable, Equatable, Sendable {
    public static let maximumServerCount = 20

    public private(set) var servers: [SavedServer]

    public init(servers: [SavedServer] = []) {
        var seenOrigins = Set<String>()
        self.servers = servers
            .sorted { $0.lastConnectedAt > $1.lastConnectedAt }
            .filter { seenOrigins.insert($0.origin).inserted }
            .prefix(Self.maximumServerCount)
            .map { $0 }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(servers: try container.decode([SavedServer].self, forKey: .servers))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(servers, forKey: .servers)
    }

    public var mostRecent: SavedServer? {
        servers.first
    }

    public mutating func record(_ profile: ConnectionProfile, at date: Date = .now) {
        servers.removeAll { $0.origin == profile.origin }
        servers.insert(SavedServer(profile: profile, lastConnectedAt: date), at: 0)
        if servers.count > Self.maximumServerCount {
            servers.removeLast(servers.count - Self.maximumServerCount)
        }
    }

    public mutating func remove(_ server: SavedServer) {
        servers.removeAll { $0.id == server.id }
    }

    public mutating func removeAll() {
        servers.removeAll()
    }

    private enum CodingKeys: String, CodingKey {
        case servers
    }
}
