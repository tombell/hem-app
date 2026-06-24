import SwiftUI

struct ExportDisplayResult {
  let message: String
  let systemImage: String
  let tint: Color

  static func success(_ message: String) -> ExportDisplayResult {
    ExportDisplayResult(message: message, systemImage: "checkmark.circle.fill", tint: .green)
  }

  static func failure(_ message: String) -> ExportDisplayResult {
    ExportDisplayResult(message: message, systemImage: "exclamationmark.triangle.fill", tint: .red)
  }
}
