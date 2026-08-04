import Foundation
import Observation

@MainActor
@Observable
final class BonjourDiscovery: NSObject {
    private(set) var servers: [DiscoveredServer] = []
    private(set) var isScanning = false
    private(set) var errorMessage: String?

    private let serviceType = "_devicehub._tcp."
    private var browser: NetServiceBrowser?
    private var services: [String: NetService] = [:]

    func start() {
        stop()
        errorMessage = nil
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.schedule(in: .main, forMode: .common)
        browser.searchForServices(ofType: serviceType, inDomain: "local.")
        self.browser = browser
        isScanning = true
    }

    func stop() {
        browser?.stop()
        browser?.remove(from: .main, forMode: .common)
        browser?.delegate = nil
        for service in services.values {
            service.stop()
            service.delegate = nil
        }
        services.removeAll()
        servers.removeAll()
        browser = nil
        isScanning = false
    }

    private func found(_ service: NetService) {
        let id = serviceID(service)
        services[id] = service
        service.delegate = self
        service.schedule(in: .main, forMode: .common)
        service.resolve(withTimeout: 5)
    }

    private func removed(_ service: NetService) {
        let id = serviceID(service)
        services[id]?.stop()
        services.removeValue(forKey: id)
        servers.removeAll { $0.id == id }
    }

    private func resolved(_ service: NetService) {
        guard services[serviceID(service)] != nil,
              let host = service.hostName?.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
              !host.isEmpty,
              service.port > 0 else {
            return
        }

        let record = service.txtRecordData().map(NetService.dictionary(fromTXTRecord:)) ?? [:]
        let values = record.reduce(into: [String: String]()) { result, item in
            if let value = String(data: item.value, encoding: .utf8) {
                result[item.key] = value
            }
        }
        guard values["protocol"] == "1",
              values["transport"] == "http-ws",
              values["targets"]?.split(separator: ",").contains("ios") == true else {
            return
        }

        let server = DiscoveredServer(
            id: serviceID(service),
            name: service.name,
            host: host,
            port: service.port,
            transport: values["transport"] ?? "http-ws"
        )
        servers.removeAll { $0.id == server.id }
        servers.append(server)
        servers.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func serviceID(_ service: NetService) -> String {
        "\(service.domain)|\(service.type)|\(service.name)"
    }
}

// NetService callbacks are scheduled on the main run loop and handed off synchronously.
private final class NetServiceReference: @unchecked Sendable {
    nonisolated(unsafe) let value: NetService

    nonisolated init(_ value: NetService) {
        self.value = value
    }
}

extension BonjourDiscovery: NetServiceBrowserDelegate, NetServiceDelegate {
    nonisolated func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        let reference = NetServiceReference(service)
        MainActor.assumeIsolated {
            found(reference.value)
        }
    }

    nonisolated func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        let reference = NetServiceReference(service)
        MainActor.assumeIsolated {
            removed(reference.value)
        }
    }

    nonisolated func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        MainActor.assumeIsolated {
            isScanning = false
            errorMessage = "Local network discovery failed."
        }
    }

    nonisolated func netServiceDidResolveAddress(_ sender: NetService) {
        let reference = NetServiceReference(sender)
        MainActor.assumeIsolated {
            resolved(reference.value)
        }
    }

    nonisolated func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let serviceName = sender.name
        MainActor.assumeIsolated {
            errorMessage = "Unable to resolve \(serviceName)."
        }
    }
}
