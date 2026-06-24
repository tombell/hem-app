import SwiftUI

struct SettingsScreen: View {
  @Binding var endpointText: String
  @Binding var bearerToken: String
  let destinationHost: String
  let endpointState: ReadinessState
  let healthStatus: HealthAuthorizationService.Status
  let healthState: ReadinessState
  let settingsMessage: ExportDisplayResult?
  let isRequestingHealthAccess: Bool
  let result: ExportDisplayResult?
  let saveAction: () -> Void
  let requestHealthAccessAction: () async -> Void

  var body: some View {
    ScreenContainer {
      HeaderPanel(
        title: "Settings",
        subtitle: "Hem Web and Health",
        systemImage: "gearshape.fill",
        tint: .blue
      )
      DestinationPanel(
        endpointText: $endpointText,
        bearerToken: $bearerToken,
        destinationHost: destinationHost,
        endpointState: endpointState,
        settingsMessage: settingsMessage,
        saveAction: saveAction
      )
      HealthPanel(
        healthStatus: healthStatus,
        healthState: healthState,
        isRequestingHealthAccess: isRequestingHealthAccess,
        requestAction: requestHealthAccessAction
      )
      ResultPanel(result: result)
    }
  }
}
