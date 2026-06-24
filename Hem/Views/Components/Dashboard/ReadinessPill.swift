import SwiftUI

struct ReadinessPill: View {
  let title: String
  let state: ReadinessState

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Image(systemName: state.systemImage)
        .font(.caption.weight(.bold))
        .foregroundStyle(state.tint)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text(state.title)
          .font(.caption2.weight(.bold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: 50)
    .padding(.horizontal, 9)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}
