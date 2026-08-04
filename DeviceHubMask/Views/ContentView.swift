import SwiftUI

struct ContentView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            if model.isServerConnected {
                ServerDashboardView(model: model)
            } else {
                ConnectionView(model: model)
            }
        }
        .task {
            model.startDiscovery()
        }
    }
}
