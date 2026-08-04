import Foundation

public enum Orientation: String, Codable, Sendable, Equatable {
    case portrait
    case portraitUpsideDown = "portrait_upside_down"
    case landscapeLeft = "landscape_left"
    case landscapeRight = "landscape_right"

    public var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
}
