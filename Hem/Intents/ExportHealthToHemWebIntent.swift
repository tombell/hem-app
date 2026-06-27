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
      return .result(dialog: "\(ExportErrorPresentation.message(for: error))")
    }
  }
}
