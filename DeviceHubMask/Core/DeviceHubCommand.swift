import Foundation

public enum DeviceHubCommand: Encodable, Sendable {
    case clientHello(protocolVersion: Int, platform: String, clientVersion: String, capabilities: [String])
    case multiTouch(contacts: [MultiTouchContact])
    case button(name: String)
    case buttonDown(name: String)
    case buttonUp(name: String)
    case systemAction(action: String)
    case rotate(direction: RotationDirection)
    case videoDemand(active: Bool)
    case audioDemand(active: Bool)
    case browserFrameAccepted(sequence: UInt64)
    case framePresented(sequence: UInt64)
    case browserVideoKeyframe

    public enum RotationDirection: String, Encodable, Sendable {
        case left
        case right
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .clientHello(let protocolVersion, let platform, let clientVersion, let capabilities):
            try container.encode("client_hello", forKey: .type)
            try container.encode(protocolVersion, forKey: .protocolVersion)
            try container.encode(platform, forKey: .platform)
            try container.encode(clientVersion, forKey: .clientVersion)
            try container.encode(capabilities, forKey: .capabilities)
        case .multiTouch(let contacts):
            try container.encode("multi_touch", forKey: .type)
            try container.encode(contacts, forKey: .contacts)
        case .button(let name):
            try container.encode("button", forKey: .type)
            try container.encode(name, forKey: .name)
        case .buttonDown(let name):
            try container.encode("button_down", forKey: .type)
            try container.encode(name, forKey: .name)
        case .buttonUp(let name):
            try container.encode("button_up", forKey: .type)
            try container.encode(name, forKey: .name)
        case .systemAction(let action):
            try container.encode("system_action", forKey: .type)
            try container.encode(action, forKey: .action)
        case .rotate(let direction):
            try container.encode("rotate", forKey: .type)
            try container.encode(direction, forKey: .direction)
        case .videoDemand(let active):
            try container.encode("video_demand", forKey: .type)
            try container.encode(active, forKey: .active)
        case .audioDemand(let active):
            try container.encode("audio_demand", forKey: .type)
            try container.encode(active, forKey: .active)
        case .browserFrameAccepted(let sequence):
            try container.encode("browser_frame_accepted", forKey: .type)
            try container.encode(String(sequence), forKey: .sequence)
        case .framePresented(let sequence):
            try container.encode("frame_presented", forKey: .type)
            try container.encode(String(sequence), forKey: .sequence)
        case .browserVideoKeyframe:
            try container.encode("browser_video_keyframe", forKey: .type)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case protocolVersion = "protocol_version"
        case platform
        case clientVersion = "client_version"
        case capabilities
        case contacts
        case name
        case action
        case direction
        case active
        case sequence
    }
}
