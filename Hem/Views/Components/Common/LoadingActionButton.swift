import SwiftUI

struct LoadingActionButton: View {
  let title: String
  let systemImage: String
  let isLoading: Bool
  let action: () async -> Void

  var body: some View {
    Button {
      Task {
        await action()
      }
    } label: {
      if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity)
      } else {
        Label(title, systemImage: systemImage)
          .frame(maxWidth: .infinity)
      }
    }
    .disabled(isLoading)
  }
}
