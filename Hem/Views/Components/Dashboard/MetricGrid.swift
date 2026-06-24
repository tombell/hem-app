import SwiftUI

struct MetricGrid: View {
  let items: [MetricItem]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 7) {
      ForEach(items) { item in
        HStack(spacing: 7) {
          Image(systemName: item.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(item.tint)
            .frame(width: 16)

          Text(item.title)
            .font(.caption.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)

          Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(.tertiarySystemGroupedBackground))
        )
      }
    }
  }

  private let columns = [
    GridItem(.flexible(), spacing: 7),
    GridItem(.flexible(), spacing: 7),
  ]
}
