import Foundation

public enum MediaPacket: Sendable {
    case video(VideoPacket)
    case audio(AudioPacket)
}
