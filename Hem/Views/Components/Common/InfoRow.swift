import SwiftUI

struct InfoRow: View {
  let title: String
  let value: String
  let systemImage: String
  let tint: Color

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 20)

      Text(title)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)

      Spacer(minLength: 10)

      Text(value)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
  }
}
