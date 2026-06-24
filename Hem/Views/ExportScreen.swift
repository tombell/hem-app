import SwiftUI

struct ExportScreen: View {
  let rangeLabel: String
  let endpointState: ReadinessState
  let tokenState: ReadinessState
  let healthState: ReadinessState
  @Binding var selectedStartDate: Date
  @Binding var selectedThroughDate: Date
  let isExporting: Bool
  let result: ExportDisplayResult?
  let exportAction: () async -> Void

  var body: some View {
    ScreenContainer {
      HeaderPanel(
        title: "Hem",
        subtitle: "Health data to Hem Web",
        systemImage: "heart.text.square.fill",
        tint: .red
      )
      ReadinessPanel(
        endpointState: endpointState,
        tokenState: tokenState,
        healthState: healthState
      )
      ExportPanel(
        startDate: $selectedStartDate,
        throughDate: $selectedThroughDate,
        rangeLabel: rangeLabel,
        isExporting: isExporting,
        exportAction: exportAction
      )
      ResultPanel(result: result)
    }
  }
}
