import Foundation

public struct TouchSurfaceSize: Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct VideoFrameSize: Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct DisplayedVideoRect: Equatable, Sendable {
    public let left: Double
    public let top: Double
    public let width: Double
    public let height: Double

    public init(left: Double, top: Double, width: Double, height: Double) {
        self.left = left
        self.top = top
        self.width = width
        self.height = height
    }
}

public enum TouchGeometry {
    public static func displayedVideoSize(video: VideoFrameSize?, orientation: Orientation) -> VideoFrameSize? {
        guard let video else { return nil }
        if orientation.isLandscape {
            return VideoFrameSize(width: video.height, height: video.width)
        }
        return video
    }

    public static func displayedVideoRect(
        surface: TouchSurfaceSize,
        video: VideoFrameSize?,
        orientation: Orientation,
        contentMode: DeviceHubContentMode = .fit
    ) -> DisplayedVideoRect {
        let surfaceWidth = max(surface.width, 1)
        let surfaceHeight = max(surface.height, 1)
        guard let displayedVideo = displayedVideoSize(video: video, orientation: orientation),
              displayedVideo.width > 0,
              displayedVideo.height > 0 else {
            return DisplayedVideoRect(left: 0, top: 0, width: surfaceWidth, height: surfaceHeight)
        }
        let scale: Double
        switch contentMode {
        case .fit:
            scale = min(surfaceWidth / displayedVideo.width, surfaceHeight / displayedVideo.height)
        case .fill:
            scale = max(surfaceWidth / displayedVideo.width, surfaceHeight / displayedVideo.height)
        }
        let displayedWidth = max(displayedVideo.width * scale, 1)
        let displayedHeight = max(displayedVideo.height * scale, 1)
        return DisplayedVideoRect(
            left: (surfaceWidth - displayedWidth) / 2,
            top: (surfaceHeight - displayedHeight) / 2,
            width: displayedWidth,
            height: displayedHeight
        )
    }

    public static func normalize(
        location: (x: Double, y: Double),
        surface: TouchSurfaceSize,
        video: VideoFrameSize?,
        orientation: Orientation,
        contentMode: DeviceHubContentMode = .fit
    ) -> (x: Double, y: Double) {
        let rect = displayedVideoRect(surface: surface, video: video, orientation: orientation, contentMode: contentMode)
        return (
            x: clamp((location.x - rect.left) / rect.width),
            y: clamp((location.y - rect.top) / rect.height)
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

public enum DeviceHubContentMode: Sendable {
    case fit
    case fill
}
