import Foundation

public struct ConnectionProfile: Codable, Equatable, Sendable {
    public let origin: String
    public let token: String

    public init(origin: String, token: String) throws {
        self.origin = try Self.normalizeOrigin(origin)
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedToken.isEmpty else {
            throw DeviceHubError.missingAccessToken
        }
        self.token = normalizedToken
    }

    public init(serverInput: String, tokenInput: String) throws {
        let trimmedInput = serverInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = Self.addSchemeIfNeeded(trimmedInput)
        guard let components = URLComponents(string: candidate) else {
            throw DeviceHubError.invalidServerAddress
        }

        let fragmentToken = Self.queryItems(in: components.fragment ?? "?")
            .first(where: { $0.name == "access_token" })?.value
        let queryToken = components.queryItems?
            .first(where: { $0.name == "access_token" })?.value
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? (fragmentToken ?? queryToken ?? "") : tokenInput
        try self.init(origin: candidate, token: token)
    }

    public func httpURL(path: String) throws -> URL {
        guard path.hasPrefix("/") else {
            throw DeviceHubError.invalidServerAddress
        }
        guard let base = URL(string: origin), var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw DeviceHubError.invalidServerAddress
        }
        components.path = path
        components.query = nil
        components.fragment = nil
        guard let url = components.url else {
            throw DeviceHubError.invalidServerAddress
        }
        return url
    }

    public func websocketURL(deviceID: String) throws -> URL {
        guard let base = URL(string: origin), var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw DeviceHubError.invalidServerAddress
        }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/api/ws"
        components.queryItems = [URLQueryItem(name: "device_id", value: deviceID)]
        components.fragment = nil
        guard let url = components.url else {
            throw DeviceHubError.invalidServerAddress
        }
        return url
    }

    private static func normalizeOrigin(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = addSchemeIfNeeded(trimmed)
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty else {
            if URLComponents(string: candidate)?.scheme != nil {
                throw DeviceHubError.unsupportedServerScheme
            }
            throw DeviceHubError.invalidServerAddress
        }

        var normalized = components
        normalized.path = ""
        normalized.query = nil
        normalized.fragment = nil
        guard var result = normalized.url?.absoluteString else {
            throw DeviceHubError.invalidServerAddress
        }
        while result.last == "/" {
            result.removeLast()
        }
        return result
    }

    private static func addSchemeIfNeeded(_ value: String) -> String {
        guard !value.isEmpty else { return value }
        if value.range(of: #"^[a-zA-Z][a-zA-Z0-9+.-]*://"#, options: .regularExpression) != nil {
            return value
        }
        return "http://\(value)"
    }

    private static func queryItems(in fragment: String) -> [URLQueryItem] {
        URLComponents(string: "?\(fragment)")?.queryItems ?? []
    }
}
