import Foundation

public struct AudioPacket: Sendable {
    public let sampleRate: Int
    public let channels: Int
    public let data: Data

    public init(sampleRate: Int, channels: Int, data: Data) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.data = data
    }
}
