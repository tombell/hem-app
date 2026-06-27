import Foundation

struct HealthExportRunner {
  private let coordinator: ExportCoordinator

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: HealthExportService = HealthExportService(),
    client: HemWebClient = HemWebClient(),
    historyStore: any ExportHistoryStoring = ExportHistoryStore(),
    checkpointStore: ExportCheckpointStore = ExportCheckpointStore()
  ) {
    coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      exportService: exportService,
      client: client,
      historyStore: historyStore,
      checkpointStore: checkpointStore
    )
  }

  func exportPreviousFullWeek() async throws -> ExportSummary {
    let range = WeekRange.previousFullWeek()
    return try await coordinator.export(
      range: range,
      mode: .shortcut,
      metrics: Set(ExportMetricCategory.allCases)
    )
  }

  func export(range: WeekRange) async throws -> ExportSummary {
    try await coordinator.export(
      range: range,
      metrics: Set(ExportMetricCategory.allCases)
    )
  }
}

struct ExportSummary: Equatable {
  let range: WeekRange
  let destinationHost: String
  let dailyMetricCount: Int
  let sampleCount: Int
  let workoutCount: Int
  let sleepSampleCount: Int

  var intentDialog: String {
    "Exported Health data for \(range.displayLabel)."
  }
}
