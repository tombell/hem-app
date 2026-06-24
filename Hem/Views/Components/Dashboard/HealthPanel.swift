import SwiftUI

struct HealthPanel: View {
  let healthStatus: HealthAuthorizationService.Status
  let healthState: ReadinessState
  let isRequestingHealthAccess: Bool
  let requestAction: () async -> Void

  var body: some View {
    DashboardPanel(title: "Health", systemImage: "heart.text.square", tint: .red) {
      InfoRow(
        title: "Access",
        value: healthStatus.displayName,
        systemImage: healthState.systemImage,
        tint: healthState.tint
      )

      Text(healthStatus.detail)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      LoadingActionButton(
        title: "Request Access",
        systemImage: "heart",
        isLoading: isRequestingHealthAccess,
        action: requestAction
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)
      .accessibilityIdentifier("request-health-access-button")
    }
  }
}
