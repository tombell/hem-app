import SwiftUI

struct MetricSelectionGrid: View {
  @Binding var selectedMetrics: Set<ExportMetricCategory>

  var body: some View {
    LazyVGrid(columns: columns, spacing: 7) {
      ForEach(ExportMetricCategory.allCases) { metric in
        Button {
          toggle(metric)
        } label: {
          HStack(spacing: 7) {
            Image(systemName: metric.systemImage)
              .font(.caption.weight(.semibold))
              .foregroundStyle(metric.tint)
              .frame(width: 16)

            Text(metric.title)
              .font(.caption.weight(.medium))
              .foregroundStyle(.primary)
              .lineLimit(1)
              .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            Image(systemName: selectedMetrics.contains(metric) ? "checkmark.circle.fill" : "circle")
              .font(.caption.weight(.semibold))
              .foregroundStyle(selectedMetrics.contains(metric) ? metric.tint : .secondary)
          }
          .padding(.horizontal, 9)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color(.tertiarySystemGroupedBackground))
          )
        }
        .buttonStyle(.plain)
      }
    }
  }

  private let columns = [
    GridItem(.flexible(), spacing: 7),
    GridItem(.flexible(), spacing: 7),
  ]

  private func toggle(_ metric: ExportMetricCategory) {
    if selectedMetrics.contains(metric) {
      selectedMetrics.remove(metric)
    } else {
      selectedMetrics.insert(metric)
    }
  }
}
