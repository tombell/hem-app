import SwiftUI

struct HealthPanel: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    DashboardPanel(title: "Health", systemImage: "heart.text.square", tint: .red) {
      InfoRow(
        title: "Access",
        value: model.healthStatus.displayName,
        systemImage: model.healthState.systemImage,
        tint: model.healthState.tint
      )

      Text(model.healthStatus.detail)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      LoadingActionButton(
        title: "Request Access",
        systemImage: "heart",
        isLoading: model.isRequestingHealthAccess,
        action: model.requestHealthAccess
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)
      .accessibilityIdentifier("request-health-access-button")
    }
  }
}
