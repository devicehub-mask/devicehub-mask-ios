import Foundation

public enum DeviceControlAction: String, CaseIterable, Identifiable, Sendable {
    case home
    case lock
    case volumeUp
    case volumeDown
    case mute
    case siri
    case actionButton
    case appSwitcher
    case rotateLeft
    case rotateRight

    public var id: Self { self }

    public var requiredCapability: String {
        switch self {
        case .home, .lock, .volumeUp, .volumeDown, .mute, .siri, .actionButton:
            "button"
        case .appSwitcher:
            "system_action"
        case .rotateLeft, .rotateRight:
            "rotate"
        }
    }

    public var command: DeviceHubCommand {
        switch self {
        case .home:
            .button(name: "home")
        case .lock:
            .button(name: "lock")
        case .volumeUp:
            .button(name: "volume-up")
        case .volumeDown:
            .button(name: "volume-down")
        case .mute:
            .button(name: "mute")
        case .siri:
            .button(name: "siri")
        case .actionButton:
            .button(name: "action")
        case .appSwitcher:
            .systemAction(action: "app-switcher")
        case .rotateLeft:
            .rotate(direction: .left)
        case .rotateRight:
            .rotate(direction: .right)
        }
    }
}
