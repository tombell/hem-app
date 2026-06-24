import SwiftUI

struct HeaderPanel: View {
  let title: String
  let subtitle: String
  let detail: String?
  let systemImage: String
  let tint: Color

  init(
    title: String,
    subtitle: String,
    detail: String? = nil,
    systemImage: String,
    tint: Color
  ) {
    self.title = title
    self.subtitle = subtitle
    self.detail = detail
    self.systemImage = systemImage
    self.tint = tint
  }

  var body: some View {
    HStack(spacing: 10) {
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(tint.gradient)

        Image(systemName: systemImage)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.white)
      }
      .frame(width: 46, height: 46)

      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.system(.title2, design: .rounded, weight: .bold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Text(subtitle)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)

        if let detail {
          Text(detail)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}
