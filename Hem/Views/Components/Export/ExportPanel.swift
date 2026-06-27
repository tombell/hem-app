import SwiftUI

struct ExportPanel: View {
  @Binding var startDate: Date
  @Binding var throughDate: Date
  @Binding var selectedMetrics: Set<ExportMetricCategory>
  let rangeLabel: String
  let isPreparing: Bool
  let canExport: Bool
  let canExportSinceLastSuccess: Bool
  let previewAction: () async -> Void
  let incrementalAction: () async -> Void

  var body: some View {
    DashboardPanel(title: "Export", systemImage: "calendar.badge.clock", tint: .teal) {
      DateRangePicker(
        startDate: $startDate,
        throughDate: $throughDate
      )

      Divider()

      InfoRow(
        title: "Range",
        value: rangeLabel,
        systemImage: "calendar",
        tint: .teal
      )

      MetricSelectionGrid(selectedMetrics: $selectedMetrics)

      LoadingActionButton(
        title: "Preview Export",
        systemImage: "doc.text.magnifyingglass",
        isLoading: isPreparing,
        action: previewAction
      )
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)
      .disabled(!canExport)
      .accessibilityIdentifier("preview-export-button")

      LoadingActionButton(
        title: "Since Last Success",
        systemImage: "clock.badge.checkmark",
        isLoading: isPreparing,
        action: incrementalAction
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)
      .disabled(!canExport || !canExportSinceLastSuccess)
      .accessibilityIdentifier("export-since-last-success-button")
    }
  }
}
