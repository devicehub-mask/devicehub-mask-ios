import XCTest
@testable import DeviceHubCore

final class CommandEncodingTests: XCTestCase {
    func testClientHelloUsesWireNames() throws {
        let command = DeviceHubCommand.clientHello(
            protocolVersion: 1,
            platform: "ios",
            clientVersion: "1.0.0",
            capabilities: ["native_hevc"]
        )
        let data = try JSONEncoder().encode(command)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "client_hello")
        XCTAssertEqual(object["protocol_version"] as? Int, 1)
        XCTAssertEqual(object["client_version"] as? String, "1.0.0")
    }

    func testBrowserFrameAcknowledgementUsesStringSequence() throws {
        let command = DeviceHubCommand.browserFrameAccepted(sequence: 42)
        let data = try JSONEncoder().encode(command)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "browser_frame_accepted")
        XCTAssertEqual(object["sequence"] as? String, "42")
    }
}
