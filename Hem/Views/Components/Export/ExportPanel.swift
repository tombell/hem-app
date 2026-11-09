import SwiftUI

struct ExportPanel: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    @Bindable var model = model

    DashboardPanel(title: "Export", systemImage: "calendar.badge.clock", tint: .teal) {
      DateRangePicker(
        startDate: $model.selectedStartDate,
        throughDate: $model.selectedThroughDate
      )

      Divider()

      InfoRow(
        title: "Range",
        value: model.selectedRange?.displayLabel ?? "—",
        systemImage: "calendar",
        tint: .teal
      )

      MetricSelectionGrid(selectedMetrics: $model.selectedMetrics)

      LoadingActionButton(
        title: "Preview Export",
        systemImage: "doc.text.magnifyingglass",
        isLoading: model.isExporting,
        action: model.preparePreview
      )
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)
      .disabled(!model.canExport)
      .accessibilityIdentifier("preview-export-button")

      LoadingActionButton(
        title: "Since Last Success",
        systemImage: "clock.badge.checkmark",
        isLoading: model.isExporting,
        action: model.exportSinceLastSuccess
      )
      .buttonStyle(.bordered)
      .controlSize(.regular)
      .disabled(!model.canExport || !model.canExportSinceLastSuccess)
      .accessibilityIdentifier("export-since-last-success-button")
    }
  }
}
