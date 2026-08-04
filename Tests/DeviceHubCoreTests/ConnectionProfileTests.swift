import XCTest
@testable import DeviceHubCore

final class ConnectionProfileTests: XCTestCase {
    func testFullHeadlessURLProvidesFragmentToken() throws {
        let profile = try ConnectionProfile(
            serverInput: "http://127.0.0.1:8080/#access_token=secret-token",
            tokenInput: ""
        )

        XCTAssertEqual(profile.origin, "http://127.0.0.1:8080")
        XCTAssertEqual(profile.token, "secret-token")
    }

    func testWebSocketURLUsesSecureSchemeAndEscapesDeviceID() throws {
        let profile = try ConnectionProfile(origin: "https://example.test/", token: "token")
        let url = try profile.websocketURL(deviceID: "phone::wifi")

        XCTAssertEqual(url.scheme, "wss")
        XCTAssertEqual(url.path, "/api/ws")
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "phone::wifi")
    }

    func testRejectsMissingToken() {
        XCTAssertThrowsError(try ConnectionProfile(origin: "127.0.0.1:8080", token: "")) { error in
            XCTAssertEqual(error as? DeviceHubError, .missingAccessToken)
        }
    }
}
