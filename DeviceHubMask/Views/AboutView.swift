import SwiftUI

struct AboutView: View {
    private let versionInfo = AppVersionInfo.current

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.largeTitle)
                        .foregroundStyle(DeviceHubDesign.accent)
                        .accessibilityHidden(true)
                    Text("DeviceHub Mask")
                        .font(.title2.bold())
                    Text("Native headless remote control client")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .accessibilityElement(children: .combine)
            }

            Section("App Information") {
                LabeledContent("Version", value: versionInfo.version)
                LabeledContent("Build", value: versionInfo.build)
            }

            Section("Links") {
                if let projectURL = URL(string: "https://github.com/boa-z/devicehub-mask-ios") {
                    Link("Project on GitHub", destination: projectURL)
                }
                if let sourceURL = URL(string: "https://raw.githubusercontent.com/boa-z/devicehub-mask-ios/main/.github/apps.json") {
                    Link("SideStore Source", destination: sourceURL)
                }
            }

            Section("Privacy") {
                Text("Server addresses and access tokens are stored in the device Keychain. Device data is sent only to servers you choose.")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
