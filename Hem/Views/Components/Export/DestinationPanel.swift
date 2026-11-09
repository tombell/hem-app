import SwiftUI

struct DestinationPanel: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    @Bindable var model = model

    DashboardPanel(title: "Hem Web", systemImage: "network", tint: .blue) {
      FieldRow(title: "Endpoint", systemImage: "link") {
        TextField(
          "Endpoint URL",
          text: $model.endpointText,
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
          text: $model.bearerToken,
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
        value: model.resolvedDestinationHost,
        systemImage: model.endpointState.systemImage,
        tint: model.endpointState.tint
      )

      Button(action: model.saveSettings) {
        Label("Save Settings", systemImage: "checkmark.circle")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)

      LoadingActionButton(
        title: "Test Connection",
        systemImage: "network",
        isLoading: model.isTestingConnection,
        action: model.testConnection
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)

      if let settingsMessage = model.settingsMessage {
        ResultBanner(result: settingsMessage)
      }
    }
  }
}
