import SwiftUI
import UIKit

struct DeviceHubTouchSurface: UIViewRepresentable {
    let enabled: Bool
    let video: VideoFrameSize?
    let orientation: Orientation
    let onContacts: ([MultiTouchContact]) -> Void

    func makeUIView(context: Context) -> DeviceHubTouchSurfaceView {
        let view = DeviceHubTouchSurfaceView()
        view.configure(enabled: enabled, video: video, orientation: orientation, onContacts: onContacts)
        return view
    }

    func updateUIView(_ uiView: DeviceHubTouchSurfaceView, context: Context) {
        uiView.configure(enabled: enabled, video: video, orientation: orientation, onContacts: onContacts)
    }
}

@MainActor
final class DeviceHubTouchSurfaceView: UIView {
    private var enabled = false
    private var video: VideoFrameSize?
    private var orientation = Orientation.portrait
    private var onContacts: (([MultiTouchContact]) -> Void)?
    private var activeTouches: [ObjectIdentifier: UITouch] = [:]
    private var identities: [ObjectIdentifier: Int] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    func configure(
        enabled: Bool,
        video: VideoFrameSize?,
        orientation: Orientation,
        onContacts: @escaping ([MultiTouchContact]) -> Void
    ) {
        self.enabled = enabled
        self.video = video
        self.orientation = orientation
        self.onContacts = onContacts
        if !enabled {
            activeTouches.removeAll()
            identities.removeAll()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else { return }
        for touch in touches {
            let identifier = ObjectIdentifier(touch)
            guard identities[identifier] == nil, let identity = nextIdentity() else { continue }
            identities[identifier] = identity
            activeTouches[identifier] = touch
        }
        emit(ended: [])
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else { return }
        emit(ended: [])
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else { return }
        emit(ended: touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard enabled else { return }
        emit(ended: touches)
    }

    private func emit(ended: Set<UITouch>) {
        let surface = TouchSurfaceSize(width: Double(bounds.width), height: Double(bounds.height))
        let endedIdentifiers = Set(ended.map(ObjectIdentifier.init))
        var contacts = activeTouches.compactMap { identifier, touch -> MultiTouchContact? in
            guard !endedIdentifiers.contains(identifier) else { return nil }
            guard let identity = identities[identifier] else { return nil }
            let point = normalized(touch.location(in: self), surface: surface)
            return MultiTouchContact(identity: identity, touching: true, x: point.x, y: point.y)
        }
        contacts += ended.compactMap { touch in
            let identifier = ObjectIdentifier(touch)
            guard let identity = identities[identifier] else { return nil }
            let point = normalized(touch.location(in: self), surface: surface)
            return MultiTouchContact(identity: identity, touching: false, x: point.x, y: point.y)
        }
        onContacts?(contacts)
        for identifier in endedIdentifiers {
            activeTouches.removeValue(forKey: identifier)
            identities.removeValue(forKey: identifier)
        }
    }

    private func normalized(_ point: CGPoint, surface: TouchSurfaceSize) -> (x: Double, y: Double) {
        TouchGeometry.normalize(
            location: (x: Double(point.x), y: Double(point.y)),
            surface: surface,
            video: video,
            orientation: orientation
        )
    }

    private func nextIdentity() -> Int? {
        let used = Set(identities.values)
        return (0..<5).first(where: { !used.contains($0) })
    }
}
