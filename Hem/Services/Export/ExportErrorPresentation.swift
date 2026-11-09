import Foundation
import HealthKit

enum ExportErrorPresentation {
  static func message(for error: Error) -> String {
    if let hkError = error as? HKError,
      hkError.code == .errorDatabaseInaccessible
    {
      return "Health access is not available while the iPhone is locked. Unlock and try again."
    }

    return error.localizedDescription
  }
}
