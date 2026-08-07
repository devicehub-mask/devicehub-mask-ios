import SwiftUI

struct SavedServersSection: View {
    @Bindable var model: AppModel

    var body: some View {
        if !model.connectionHistory.servers.isEmpty {
            Section("Recent Servers") {
                ForEach(model.connectionHistory.servers) { server in
                    Button {
                        model.connect(to: server)
                    } label: {
                        SavedServerRowView(server: server)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isBusy)
                    .swipeActions {
                        Button("Forget", systemImage: "trash", role: .destructive) {
                            model.forget(server)
                        }
                    }
                    .contextMenu {
                        Button("Fill Connection Form", systemImage: "square.and.pencil") {
                            model.select(server)
                        }
                        Button("Forget", systemImage: "trash", role: .destructive) {
                            model.forget(server)
                        }
                    }
                }
            }
        }
    }
}
