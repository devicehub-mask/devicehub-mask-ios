import Foundation

public struct RemoteDevice: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let udid: String
    public let name: String
    public let connection: String
    public let pairing: String
    public let sessionStatus: String?
    public let sessionPhase: SessionPhase?
    public let sessionUpdatedAtMs: Int64?
    public let sessionError: String?
    public let resources: DeviceResources?

    public init(
        id: String,
        udid: String,
        name: String,
        connection: String,
        pairing: String,
        sessionStatus: String?,
        sessionPhase: SessionPhase?,
        sessionUpdatedAtMs: Int64?,
        sessionError: String?,
        resources: DeviceResources?
    ) {
        self.id = id
        self.udid = udid
        self.name = name
        self.connection = connection
        self.pairing = pairing
        self.sessionStatus = sessionStatus
        self.sessionPhase = sessionPhase
        self.sessionUpdatedAtMs = sessionUpdatedAtMs
        self.sessionError = sessionError
        self.resources = resources
    }

    public var isActive: Bool {
        switch sessionPhase {
        case .connected, .recovering, .connecting, .disconnecting:
            true
        default:
            false
        }
    }

    public var isPaired: Bool {
        pairing == "paired" || pairing == "not_applicable"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case udid
        case name
        case connection
        case pairing
        case sessionStatus = "session_status"
        case sessionPhase = "session_phase"
        case sessionUpdatedAtMs = "session_updated_at_ms"
        case sessionError = "session_error"
        case resources
    }
}
