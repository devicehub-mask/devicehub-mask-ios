import XCTest
@testable import DeviceHubCore

final class ConnectionHistoryTests: XCTestCase {
    func testRecordingMovesUpdatedServerToFront() throws {
        let first = try ConnectionProfile(origin: "https://first.example", token: "old")
        let second = try ConnectionProfile(origin: "https://second.example", token: "second")
        let updatedFirst = try ConnectionProfile(origin: "https://first.example", token: "new")
        var history = ConnectionHistory()

        history.record(first, at: Date(timeIntervalSince1970: 1))
        history.record(second, at: Date(timeIntervalSince1970: 2))
        history.record(updatedFirst, at: Date(timeIntervalSince1970: 3))

        XCTAssertEqual(history.servers.map(\.origin), ["https://first.example", "https://second.example"])
        XCTAssertEqual(history.servers.first?.token, "new")
    }

    func testHistoryKeepsOnlyMostRecentServers() throws {
        let entries = try (0..<(ConnectionHistory.maximumServerCount + 5)).map { index in
            let profile = try ConnectionProfile(origin: "https://server-\(index).example", token: "token")
            return SavedServer(profile: profile, lastConnectedAt: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        let history = ConnectionHistory(servers: entries)

        XCTAssertEqual(history.servers.count, ConnectionHistory.maximumServerCount)
        XCTAssertEqual(history.servers.first?.origin, "https://server-24.example")
        XCTAssertEqual(history.servers.last?.origin, "https://server-5.example")
    }

    func testDecodingNormalizesDuplicateServers() throws {
        let profile = try ConnectionProfile(origin: "https://example.test", token: "new")
        let newer = SavedServer(profile: profile, lastConnectedAt: Date(timeIntervalSince1970: 2))
        let olderProfile = try ConnectionProfile(origin: "https://example.test", token: "old")
        let older = SavedServer(profile: olderProfile, lastConnectedAt: Date(timeIntervalSince1970: 1))
        let data = try JSONEncoder().encode(["servers": [newer, older]])

        let history = try JSONDecoder().decode(ConnectionHistory.self, from: data)

        XCTAssertEqual(history.servers, [newer])
    }
}
