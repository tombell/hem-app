import SwiftUI

struct ExportScreen: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    ScreenContainer {
      HeaderPanel(
        title: "Hem",
        subtitle: "Health data to Hem Web",
        systemImage: "heart.text.square.fill",
        tint: .red
      )
      ReadinessPanel(
        endpointState: model.endpointState,
        tokenState: model.tokenState,
        healthState: model.healthState
      )
      ExportPanel()
      ResultPanel(result: model.lastResult)
    }
  }
}
