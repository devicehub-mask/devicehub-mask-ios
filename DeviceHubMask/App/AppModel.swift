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

    @ObservationIgnored let discovery = BonjourDiscovery()

    private(set) var api: DeviceHubAPI?
    private let keychain = KeychainConnectionStore()

    init() {
        if let profile = keychain.load() {
            serverInput = profile.origin
            tokenInput = profile.token
        }
    }

    func startDiscovery() {
        discovery.start()
    }

    func use(_ server: DiscoveredServer) {
        serverInput = server.origin
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
                try keychain.save(profile)
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
