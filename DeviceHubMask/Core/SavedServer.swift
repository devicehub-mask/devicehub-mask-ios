import Foundation

public struct SavedServer: Codable, Equatable, Identifiable, Sendable {
    public let origin: String
    public let token: String
    public let lastConnectedAt: Date

    public var id: String { origin }

    public init(profile: ConnectionProfile, lastConnectedAt: Date = .now) {
        origin = profile.origin
        token = profile.token
        self.lastConnectedAt = lastConnectedAt
    }

    public var displayName: String {
        guard let components = URLComponents(string: origin), let host = components.host else {
            return origin
        }
        if let port = components.port {
            return "\(host):\(port)"
        }
        return host
    }

    public func profile() throws -> ConnectionProfile {
        try ConnectionProfile(origin: origin, token: token)
    }
}
