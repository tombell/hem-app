import SwiftUI

struct ScreenContainer<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 12) {
          content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
      }
    }
  }
}
