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

    func testSystemActionUsesWireNames() throws {
        let data = try JSONEncoder().encode(DeviceHubCommand.systemAction(action: "app-switcher"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "system_action")
        XCTAssertEqual(object["action"] as? String, "app-switcher")
    }

    func testDeviceControlActionsMatchServerCapabilities() throws {
        let expected: [(DeviceControlAction, String, String, String)] = [
            (.home, "button", "button", "home"),
            (.lock, "button", "button", "lock"),
            (.volumeUp, "button", "button", "volume-up"),
            (.volumeDown, "button", "button", "volume-down"),
            (.mute, "button", "button", "mute"),
            (.siri, "button", "button", "siri"),
            (.actionButton, "button", "button", "action"),
            (.appSwitcher, "system_action", "system_action", "app-switcher"),
            (.rotateLeft, "rotate", "rotate", "left"),
            (.rotateRight, "rotate", "rotate", "right"),
        ]

        XCTAssertEqual(DeviceControlAction.allCases.count, expected.count)
        for (action, capability, type, wireValue) in expected {
            let data = try JSONEncoder().encode(action.command)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let value = object["name"] ?? object["action"] ?? object["direction"]

            XCTAssertEqual(action.requiredCapability, capability)
            XCTAssertEqual(object["type"] as? String, type)
            XCTAssertEqual(value as? String, wireValue)
        }
    }
}
