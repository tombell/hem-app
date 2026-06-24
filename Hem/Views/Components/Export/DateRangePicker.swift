import SwiftUI

struct DateRangePicker: View {
  @Binding var startDate: Date
  @Binding var throughDate: Date

  var body: some View {
    VStack(spacing: 8) {
      DatePicker("From", selection: $startDate, displayedComponents: .date)
        .datePickerStyle(.compact)

      Divider()

      DatePicker("Through", selection: $throughDate, in: startDate..., displayedComponents: .date)
        .datePickerStyle(.compact)
    }
    .font(.subheadline)
  }
}
