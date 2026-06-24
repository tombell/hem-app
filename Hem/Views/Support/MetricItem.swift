import SwiftUI

struct MetricItem: Identifiable {
  let title: String
  let systemImage: String
  let tint: Color

  var id: String {
    title
  }
}
