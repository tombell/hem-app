import SwiftUI

struct ResultPanel: View {
  let result: ExportDisplayResult?

  var body: some View {
    if let result {
      ResultBanner(result: result)
        .padding(.bottom, 8)
    }
  }
}
