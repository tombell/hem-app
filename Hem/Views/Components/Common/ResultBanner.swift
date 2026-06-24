import SwiftUI

struct ResultBanner: View {
  let result: ExportDisplayResult

  var body: some View {
    HStack(alignment: .top, spacing: 9) {
      Image(systemName: result.systemImage)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(result.tint)

      Text(result.message)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(result.tint.opacity(0.12))
    )
  }
}
