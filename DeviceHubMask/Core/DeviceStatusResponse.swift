import Foundation

public struct DeviceStatusResponse: Codable, Equatable, Sendable {
    public let status: String
    public let phase: SessionPhase
    public let updatedAtMs: Int64
    public let activeUdid: String?
    public let activeDeviceID: String?
    public let error: String?
    public let orientation: Orientation
    public let devices: [RemoteDevice]
    public let location: LocationStatus?

    public init(
        status: String,
        phase: SessionPhase,
        updatedAtMs: Int64,
        activeUdid: String?,
        activeDeviceID: String?,
        error: String?,
        orientation: Orientation,
        devices: [RemoteDevice],
        location: LocationStatus?
    ) {
        self.status = status
        self.phase = phase
        self.updatedAtMs = updatedAtMs
        self.activeUdid = activeUdid
        self.activeDeviceID = activeDeviceID
        self.error = error
        self.orientation = orientation
        self.devices = devices
        self.location = location
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case phase
        case updatedAtMs = "updated_at_ms"
        case activeUdid = "active_udid"
        case activeDeviceID = "active_device_id"
        case error
        case orientation
        case devices
        case location
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        phase = try container.decodeIfPresent(SessionPhase.self, forKey: .phase) ?? .disconnected
        updatedAtMs = try container.decodeIfPresent(Int64.self, forKey: .updatedAtMs) ?? 0
        activeUdid = try container.decodeIfPresent(String.self, forKey: .activeUdid)
        activeDeviceID = try container.decodeIfPresent(String.self, forKey: .activeDeviceID)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        orientation = try container.decodeIfPresent(Orientation.self, forKey: .orientation) ?? .portrait
        devices = try container.decodeIfPresent([RemoteDevice].self, forKey: .devices) ?? []
        location = try container.decodeIfPresent(LocationStatus.self, forKey: .location)
    }
}
