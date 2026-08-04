import Foundation

public struct MultiTouchContact: Codable, Equatable, Sendable {
    public let identity: Int
    public let touching: Bool
    public let x: Double
    public let y: Double

    public init(identity: Int, touching: Bool, x: Double, y: Double) {
        self.identity = identity
        self.touching = touching
        self.x = x
        self.y = y
    }
}
