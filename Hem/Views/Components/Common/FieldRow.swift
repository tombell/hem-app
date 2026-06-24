import SwiftUI

struct FieldRow<Field: View>: View {
  let title: String
  let systemImage: String
  @ViewBuilder var field: Field

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        field
          .font(.subheadline)
          .textFieldStyle(.plain)
      }
    }
    .frame(minHeight: 42)
  }
}
