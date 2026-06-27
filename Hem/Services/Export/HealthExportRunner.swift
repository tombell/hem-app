import Foundation

struct HealthExportRunner {
  private let coordinator: ExportCoordinator
  private let dateRangeStore: ExportDateRangeStore
  private let metricSelectionStore: MetricSelectionStore

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: HealthExportService = HealthExportService(),
    client: HemWebClient = HemWebClient(),
    historyStore: any ExportHistoryStoring = ExportHistoryStore(),
    checkpointStore: ExportCheckpointStore = ExportCheckpointStore(),
    dateRangeStore: ExportDateRangeStore = ExportDateRangeStore(),
    metricSelectionStore: MetricSelectionStore = MetricSelectionStore()
  ) {
    self.dateRangeStore = dateRangeStore
    self.metricSelectionStore = metricSelectionStore
    coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      exportService: exportService,
      client: client,
      historyStore: historyStore,
      checkpointStore: checkpointStore
    )
  }

  func exportSelectedDateRange() async throws -> ExportSummary {
    let defaultRange = WeekRange.previousFullWeek()
    let selectedRange = dateRangeStore.load(defaultRange: defaultRange)
    let range = try WeekRange.custom(
      from: selectedRange.startDate,
      through: selectedRange.throughDate
    )
    return try await coordinator.export(
      range: range,
      mode: .shortcut,
      metrics: metricSelectionStore.load()
    )
  }

  func exportPreviousDay() async throws -> ExportSummary {
    try await coordinator.export(
      range: WeekRange.previousDay(),
      mode: .shortcut,
      metrics: metricSelectionStore.load()
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
