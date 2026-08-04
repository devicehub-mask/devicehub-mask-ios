import SwiftUI

struct DeviceHubVideoSurface: UIViewRepresentable {
    let controller: DeviceHubMediaController
    let orientation: Orientation

    func makeUIView(context: Context) -> DeviceHubVideoView {
        let view = DeviceHubVideoView()
        view.update(orientation: orientation, contentMode: .fit)
        controller.attach(videoView: view)
        return view
    }

    func updateUIView(_ uiView: DeviceHubVideoView, context: Context) {
        uiView.update(orientation: orientation, contentMode: .fit)
        controller.attach(videoView: uiView)
    }

    static func dismantleUIView(_ uiView: DeviceHubVideoView, coordinator: ()) {
        controllerForDismantle(uiView)
    }

    private static func controllerForDismantle(_ uiView: DeviceHubVideoView) {
        uiView.reset()
    }
}
