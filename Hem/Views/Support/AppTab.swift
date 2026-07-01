import SwiftUI

enum AppTab: Hashable {
  case export
  case history
  case settings

  @ViewBuilder
  var label: some View {
    switch self {
    case .export:
      Label("Export", systemImage: "square.and.arrow.up")
    case .history:
      Label("History", systemImage: "clock.arrow.circlepath")
    case .settings:
      Label("Settings", systemImage: "gearshape")
    }
  }
}
