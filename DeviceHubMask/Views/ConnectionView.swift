import SwiftUI

struct ConnectionView: View {
    @Bindable var model: AppModel
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                ConnectionFormView(model: model)
                SavedServersSection(model: model)
                NearbyServersSection(model: model)

                if let errorMessage = model.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                }
            }
            .navigationTitle("DeviceHub Mask")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape", action: showSettings)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(model: model)
            }
        }
    }

    private func showSettings() {
        isShowingSettings = true
    }
}
