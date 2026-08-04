import Foundation

public struct LocationStatus: Codable, Equatable, Sendable {
    public let available: Bool
    public let active: Bool
    public let backend: String?
    public let latitude: Double?
    public let longitude: Double?
    public let error: String?

    public init(
        available: Bool,
        active: Bool,
        backend: String?,
        latitude: Double?,
        longitude: Double?,
        error: String?
    ) {
        self.available = available
        self.active = active
        self.backend = backend
        self.latitude = latitude
        self.longitude = longitude
        self.error = error
    }
}
