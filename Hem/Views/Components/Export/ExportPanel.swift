import SwiftUI

struct ExportPanel: View {
  @Binding var startDate: Date
  @Binding var throughDate: Date
  let rangeLabel: String
  let isExporting: Bool
  let exportAction: () async -> Void

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

      MetricGrid(items: metricItems)

      LoadingActionButton(
        title: "Export Now",
        systemImage: "square.and.arrow.up",
        isLoading: isExporting,
        action: exportAction
      )
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)
      .accessibilityIdentifier("export-now-button")
    }
  }

  private let metricItems = [
    MetricItem(title: "Steps", systemImage: "figure.walk", tint: .blue),
    MetricItem(title: "Energy", systemImage: "flame", tint: .orange),
    MetricItem(title: "Exercise", systemImage: "timer", tint: .green),
    MetricItem(
      title: "Distance", systemImage: "point.topleft.down.curvedto.point.bottomright.up",
      tint: .indigo),
    MetricItem(title: "Heart", systemImage: "heart", tint: .red),
    MetricItem(title: "Sleep", systemImage: "moon", tint: .purple),
    MetricItem(title: "Workouts", systemImage: "figure.run", tint: .cyan),
    MetricItem(title: "Body Mass", systemImage: "scalemass", tint: .brown),
  ]
}
