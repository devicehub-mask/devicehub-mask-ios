import XCTest
@testable import DeviceHubCore

final class TouchGeometryTests: XCTestCase {
    func testFitMappingClampsLetterboxedTouches() {
        let rect = TouchGeometry.displayedVideoRect(
            surface: TouchSurfaceSize(width: 400, height: 400),
            video: VideoFrameSize(width: 200, height: 400),
            orientation: .portrait
        )
        XCTAssertEqual(rect.left, 100)
        XCTAssertEqual(rect.width, 200)

        let topLeft = TouchGeometry.normalize(
            location: (x: 0, y: 0),
            surface: TouchSurfaceSize(width: 400, height: 400),
            video: VideoFrameSize(width: 200, height: 400),
            orientation: .portrait
        )
        XCTAssertEqual(topLeft.x, 0)
        XCTAssertEqual(topLeft.y, 0)
    }

    func testLandscapeSwapsDisplayedDimensions() {
        let size = TouchGeometry.displayedVideoSize(
            video: VideoFrameSize(width: 1170, height: 2532),
            orientation: .landscapeLeft
        )
        XCTAssertEqual(size, VideoFrameSize(width: 2532, height: 1170))
    }
}
