import SwiftUI

enum AppTab: Hashable {
  case export
  case settings

  @ViewBuilder
  var label: some View {
    switch self {
    case .export:
      Label("Export", systemImage: "square.and.arrow.up")
    case .settings:
      Label("Settings", systemImage: "gearshape")
    }
  }
}
