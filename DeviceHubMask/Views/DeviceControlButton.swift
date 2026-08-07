import SwiftUI

struct DeviceControlButton: View {
    let action: DeviceControlAction
    let isEnabled: Bool
    let perform: (DeviceControlAction) -> Void

    var body: some View {
        Button(action.title, systemImage: action.systemImage) {
            perform(action)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 6))
        .tint(.white)
        .frame(width: 48, height: 48)
        .disabled(!isEnabled)
        .help(action.title)
        .accessibilityInputLabels([action.title])
    }
}

extension DeviceControlAction {
    var title: String {
        switch self {
        case .home: "Home"
        case .lock: "Lock"
        case .volumeUp: "Volume Up"
        case .volumeDown: "Volume Down"
        case .mute: "Mute"
        case .siri: "Siri"
        case .actionButton: "Action Button"
        case .appSwitcher: "App Switcher"
        case .rotateLeft: "Rotate Left"
        case .rotateRight: "Rotate Right"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .lock: "lock.fill"
        case .volumeUp: "speaker.plus.fill"
        case .volumeDown: "speaker.minus.fill"
        case .mute: "speaker.slash.fill"
        case .siri: "waveform"
        case .actionButton: "bolt.fill"
        case .appSwitcher: "square.grid.2x2.fill"
        case .rotateLeft: "rotate.left"
        case .rotateRight: "rotate.right"
        }
    }
}
