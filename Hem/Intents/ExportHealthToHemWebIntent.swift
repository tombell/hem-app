import AppIntents

struct ExportHealthToHemWebIntent: AppIntent {
  static var title: LocalizedStringResource = "Export Health to Hem Web"
  static var description = IntentDescription(
    "Exports the selected Health date range to the Hem Web backend.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog {
    do {
      let summary = try await HealthExportRunner().exportSelectedDateRange()
      return .result(dialog: "\(summary.intentDialog)")
    } catch {
      throw ExportShortcutError.failed(ExportErrorPresentation.message(for: error))
    }
  }
}

struct ExportPreviousDayHealthToHemWebIntent: AppIntent {
  static var title: LocalizedStringResource = "Export Previous Day Health to Hem Web"
  static var description = IntentDescription(
    "Exports yesterday's Health data to the Hem Web backend.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog {
    do {
      let summary = try await HealthExportRunner().exportPreviousDay()
      return .result(dialog: "\(summary.intentDialog)")
    } catch {
      throw ExportShortcutError.failed(ExportErrorPresentation.message(for: error))
    }
  }
}

private enum ExportShortcutError: LocalizedError {
  case failed(String)

  var errorDescription: String? {
    switch self {
    case .failed(let message):
      message
    }
  }
}
