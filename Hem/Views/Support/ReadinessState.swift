import SwiftUI

enum ReadinessState {
  case ready
  case missing
  case invalid

  var title: String {
    switch self {
    case .ready:
      "Ready"
    case .missing:
      "Needed"
    case .invalid:
      "Blocked"
    }
  }

  var systemImage: String {
    switch self {
    case .ready:
      "checkmark.circle.fill"
    case .missing:
      "circle.dashed"
    case .invalid:
      "exclamationmark.triangle.fill"
    }
  }

  var tint: Color {
    switch self {
    case .ready:
      .green
    case .missing:
      .secondary
    case .invalid:
      .red
    }
  }
}
