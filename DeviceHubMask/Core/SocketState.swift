import Foundation

public enum SocketState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case failed
}
