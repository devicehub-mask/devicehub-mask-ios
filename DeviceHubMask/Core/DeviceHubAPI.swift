import Foundation

public struct DeviceHubAPI: Sendable {
    public let profile: ConnectionProfile
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(profile: ConnectionProfile, session: URLSession = .shared) {
        self.profile = profile
        self.session = session
        decoder = JSONDecoder()
    }

    public func status() async throws -> DeviceStatusResponse {
        try await request(path: "/api/status")
    }

    public func refreshDevices() async throws {
        try await requestVoid(path: "/api/devices/refresh", method: "PUT")
    }

    public func connectDevice(_ deviceID: String) async throws {
        try await requestVoid(path: "/api/devices/\(Self.pathSegment(deviceID))/connect", method: "PUT")
    }

    public func disconnectDevice(_ deviceID: String) async throws {
        try await requestVoid(path: "/api/devices/\(Self.pathSegment(deviceID))/connect", method: "DELETE")
    }

    public func reconnectDevice(_ deviceID: String) async throws {
        try await requestVoid(path: "/api/devices/\(Self.pathSegment(deviceID))/reconnect", method: "PUT")
    }

    public func pairDevice(_ deviceID: String) async throws -> PairDeviceResult {
        let result: PairDeviceResult = try await request(
            path: "/api/devices/\(Self.pathSegment(deviceID))/pair",
            method: "PUT",
            timeout: .seconds(100)
        )
        guard result.outcome == "paired" else {
            throw DeviceHubError.protocolViolation(result.error ?? "Device trust request was not completed.")
        }
        return result
    }

    private func request<Response: Decodable>(
        path: String,
        method: String = "GET",
        timeout: Duration = .seconds(8)
    ) async throws -> Response {
        let (data, _) = try await perform(path: path, method: method, timeout: timeout)
        guard !data.isEmpty else {
            throw DeviceHubError.protocolViolation("The server returned an empty response for \(path).")
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw DeviceHubError.protocolViolation("The server returned invalid JSON for \(path): \(error.localizedDescription)")
        }
    }

    private func requestVoid(path: String, method: String) async throws {
        _ = try await perform(path: path, method: method, timeout: .seconds(12))
    }

    private func perform(path: String, method: String, timeout: Duration) async throws -> (Data, HTTPURLResponse) {
        let url = try profile.httpURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout.timeInterval
        request.setValue("Bearer \(profile.token)", forHTTPHeaderField: "Authorization")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .timedOut {
            throw DeviceHubError.requestTimedOut(path)
        } catch {
            throw DeviceHubError.connectionClosed(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeviceHubError.protocolViolation("The server returned a non-HTTP response.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw DeviceHubError.http(
                status: httpResponse.statusCode,
                message: message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
        return (data, httpResponse)
    }

    private static func pathSegment(_ value: String) -> String {
        let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
