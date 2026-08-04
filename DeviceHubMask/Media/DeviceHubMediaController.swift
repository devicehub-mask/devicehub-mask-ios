import Foundation

@MainActor
final class DeviceHubMediaController {
    weak var videoView: DeviceHubVideoView?
    let audioPlayer = DeviceHubAudioPlayer()
    var audioError: String?

    func attach(videoView: DeviceHubVideoView) {
        self.videoView = videoView
    }

    func detach(videoView: DeviceHubVideoView) {
        if self.videoView === videoView {
            self.videoView = nil
        }
    }

    func update(orientation: Orientation) {
        videoView?.update(orientation: orientation, contentMode: .fit)
    }

    @discardableResult
    func receive(_ packet: VideoPacket) -> Bool {
        videoView?.enqueue(packet) ?? false
    }

    func receive(_ packet: AudioPacket) {
        audioError = audioPlayer.enqueue(packet)
    }

    func reset() {
        videoView?.reset()
        audioPlayer.reset()
        audioError = nil
    }
}
