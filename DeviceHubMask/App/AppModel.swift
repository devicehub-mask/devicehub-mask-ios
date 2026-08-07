import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var serverInput = ""
    var tokenInput = ""
    var isBusy = false
    var isServerConnected = false
    var status: DeviceStatusResponse?
    var errorMessage: String?
    private(set) var connectionHistory: ConnectionHistory

    @ObservationIgnored let discovery = BonjourDiscovery()

    private(set) var api: DeviceHubAPI?
    private let keychain = KeychainConnectionStore()
    private var hasStarted = false

    init() {
        do {
            connectionHistory = try keychain.loadHistory()
            if let savedServer = connectionHistory.mostRecent {
                serverInput = savedServer.origin
                tokenInput = savedServer.token
            }
        } catch {
            connectionHistory = ConnectionHistory()
            errorMessage = error.localizedDescription
        }
    }

    func start(automaticallyDiscover: Bool, automaticallyConnect: Bool) {
        guard !hasStarted else { return }
        hasStarted = true
        if automaticallyDiscover {
            discovery.start()
        }
        if automaticallyConnect, let savedServer = connectionHistory.mostRecent {
            connect(to: savedServer)
        }
    }

    func setDiscoveryEnabled(_ enabled: Bool) {
        if enabled {
            discovery.start()
        } else {
            discovery.stop()
        }
    }

    func use(_ server: DiscoveredServer) {
        serverInput = server.origin
        tokenInput = connectionHistory.servers.first(where: { $0.origin == server.origin })?.token ?? ""
    }

    func select(_ server: SavedServer) {
        serverInput = server.origin
        tokenInput = server.token
    }

    func connect(to server: SavedServer) {
        select(server)
        connect()
    }

    func connect() {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let profile = try ConnectionProfile(serverInput: serverInput, tokenInput: tokenInput)
                let client = DeviceHubAPI(profile: profile)
                let nextStatus = try await client.status()
                connectionHistory.record(profile)
                do {
                    try keychain.save(connectionHistory)
                } catch {
                    errorMessage = "Connected, but the server could not be added to history. \(error.localizedDescription)"
                }
                api = client
                status = nextStatus
                isServerConnected = true
                serverInput = profile.origin
                tokenInput = profile.token
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }

    func refresh() async {
        guard let api else { return }
        do {
            try await api.refreshDevices()
            status = try await api.status()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func connect(_ device: RemoteDevice) {
        updateDevice(device, operation: { api in
            try await api.connectDevice(device.id)
        })
    }

    func disconnect(_ device: RemoteDevice) {
        updateDevice(device, operation: { api in
            try await api.disconnectDevice(device.id)
        })
    }

    func pair(_ device: RemoteDevice) {
        updateDevice(device, operation: { api in
            _ = try await api.pairDevice(device.id)
        })
    }

    func disconnectServer() {
        api = nil
        status = nil
        isServerConnected = false
        errorMessage = nil
    }

    func forget(_ server: SavedServer) {
        let previousHistory = connectionHistory
        connectionHistory.remove(server)
        do {
            try keychain.save(connectionHistory)
        } catch {
            connectionHistory = previousHistory
            errorMessage = error.localizedDescription
        }
    }

    func clearConnectionHistory() {
        let previousHistory = connectionHistory
        connectionHistory.removeAll()
        do {
            try keychain.clear()
        } catch {
            connectionHistory = previousHistory
            errorMessage = error.localizedDescription
        }
    }

    private func updateDevice(
        _ device: RemoteDevice,
        operation: @escaping (DeviceHubAPI) async throws -> Void
    ) {
        guard !isBusy, let api else { return }
        isBusy = true
        errorMessage = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await operation(api)
                status = try await api.status()
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }
}
