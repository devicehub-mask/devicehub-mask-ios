import SwiftUI

struct ConnectionFormView: View {
    @Bindable var model: AppModel

    var body: some View {
        Section("Server") {
            TextField("Server Address", text: $model.serverInput, prompt: Text("http://192.168.1.10:8080"))
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            SecureField("Access Token", text: $model.tokenInput)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(model.connect)

            Button("Connect", systemImage: "arrow.right.circle.fill", action: model.connect)
                .buttonStyle(.borderedProminent)
                .tint(DeviceHubDesign.accent)
                .frame(maxWidth: .infinity, minHeight: DeviceHubDesign.controlHeight)
                .disabled(model.isBusy)
                .overlay(alignment: .trailing) {
                    if model.isBusy {
                        ProgressView()
                    }
                }
        }
    }
}
