import SwiftUI

struct DestinationPanel: View {
  @Binding var endpointText: String
  @Binding var bearerToken: String
  let destinationHost: String
  let endpointState: ReadinessState
  let settingsMessage: ExportDisplayResult?
  let isTestingConnection: Bool
  let saveAction: () -> Void
  let testConnectionAction: () async -> Void

  var body: some View {
    DashboardPanel(title: "Hem Web", systemImage: "network", tint: .blue) {
      FieldRow(title: "Endpoint", systemImage: "link") {
        TextField(
          "Endpoint URL",
          text: $endpointText,
          prompt: Text("Endpoint URL").foregroundStyle(.tertiary)
        )
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        .textContentType(.URL)
        .autocorrectionDisabled()
        .accessibilityIdentifier("endpoint-url-field")
      }

      Divider()

      FieldRow(title: "Bearer Token", systemImage: "key") {
        SecureField(
          "Bearer Token",
          text: $bearerToken,
          prompt: Text("Required").foregroundStyle(.tertiary)
        )
        .textInputAutocapitalization(.never)
        .textContentType(.password)
        .autocorrectionDisabled()
        .accessibilityIdentifier("bearer-token-field")
      }

      Divider()

      InfoRow(
        title: "Destination",
        value: destinationHost,
        systemImage: endpointState.systemImage,
        tint: endpointState.tint
      )

      Button(action: saveAction) {
        Label("Save Settings", systemImage: "checkmark.circle")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)

      LoadingActionButton(
        title: "Test Connection",
        systemImage: "network",
        isLoading: isTestingConnection,
        action: testConnectionAction
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)

      if let settingsMessage {
        ResultBanner(result: settingsMessage)
      }
    }
  }
}
