import SwiftUI

struct DashboardPanel<Content: View>: View {
  let title: String
  let systemImage: String
  let tint: Color
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: systemImage)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(tint)
          .frame(width: 22, height: 22)

        Text(title)
          .font(.headline)

        Spacer(minLength: 0)
      }

      content
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}
