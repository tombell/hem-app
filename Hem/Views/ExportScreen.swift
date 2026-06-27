import SwiftUI

struct ExportScreen: View {
  let rangeLabel: String
  let endpointState: ReadinessState
  let tokenState: ReadinessState
  let healthState: ReadinessState
  let records: [ExportRecord]
  @Binding var selectedStartDate: Date
  @Binding var selectedThroughDate: Date
  @Binding var selectedMetrics: Set<ExportMetricCategory>
  let isPreparing: Bool
  let canExport: Bool
  let canExportSinceLastSuccess: Bool
  let result: ExportDisplayResult?
  let previewAction: () async -> Void
  let incrementalAction: () async -> Void
  let retryAction: (UUID) async -> Void
  let viewAllHistoryAction: () -> Void

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
        selectedMetrics: $selectedMetrics,
        rangeLabel: rangeLabel,
        isPreparing: isPreparing,
        canExport: canExport,
        canExportSinceLastSuccess: canExportSinceLastSuccess,
        previewAction: previewAction,
        incrementalAction: incrementalAction
      )
      ExportHistoryPanel(
        records: records,
        retryAction: retryAction,
        viewAllAction: viewAllHistoryAction
      )
      ResultPanel(result: result)
    }
  }
}
