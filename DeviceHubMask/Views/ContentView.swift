import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel
    @AppStorage(AppSettingKey.automaticallyDiscoverServers) private var automaticallyDiscoverServers = true
    @AppStorage(AppSettingKey.automaticallyConnectLastServer) private var automaticallyConnectLastServer = false

    var body: some View {
        Group {
            if model.isServerConnected {
                ServerDashboardView(model: model)
            } else {
                ConnectionView(model: model)
            }
        }
        .task {
            start()
        }
    }

    private func start() {
        model.start(
            automaticallyDiscover: automaticallyDiscoverServers,
            automaticallyConnect: automaticallyConnectLastServer
        )
    }
}
