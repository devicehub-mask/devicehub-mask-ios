import Foundation

public struct VideoPacket: Sendable {
    public let keyframe: Bool
    public let timestamp: UInt64
    public let sequence: UInt64
    public let generation: UInt64
    public let width: Int
    public let height: Int
    public let data: Data

    public init(
        keyframe: Bool,
        timestamp: UInt64,
        sequence: UInt64,
        generation: UInt64,
        width: Int,
        height: Int,
        data: Data
    ) {
        self.keyframe = keyframe
        self.timestamp = timestamp
        self.sequence = sequence
        self.generation = generation
        self.width = width
        self.height = height
        self.data = data
    }
}
