import SwiftUI

struct SettingsScreen: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    ScreenContainer {
      HeaderPanel(
        title: "Settings",
        subtitle: "Hem Web and Health",
        systemImage: "gearshape.fill",
        tint: .blue
      )
      DestinationPanel()
      HealthPanel()
      ResultPanel(result: model.lastResult)
    }
  }
}
