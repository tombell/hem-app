import Foundation

struct HealthExportRunner {
  private let coordinator: ExportCoordinator
  private let dateRangeStore: ExportDateRangeStore
  private let metricSelectionStore: MetricSelectionStore

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: any HealthExportServicing = HealthExportService(),
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

  func exportSelectedDateRange() async throws -> ExportRunResult {
    let defaultRange = WeekRange.previousFullWeek()
    let selectedRange = dateRangeStore.load(defaultRange: defaultRange)
    let range = try WeekRange.custom(
      from: selectedRange.startDate,
      through: selectedRange.throughDate
    )
    return try await exportShortcut(range: range)
  }

  func exportPreviousDay() async throws -> ExportRunResult {
    try await exportShortcut(range: WeekRange.previousDay())
  }

  func export(range: WeekRange) async throws -> ExportSummary {
    try await coordinator.export(
      range: range,
      metrics: Set(ExportMetricCategory.allCases)
    )
  }

  private func exportShortcut(range: WeekRange) async throws -> ExportRunResult {
    do {
      let summary = try await coordinator.export(
        range: range,
        mode: .shortcut,
        metrics: metricSelectionStore.load()
      )
      return .exported(summary)
    } catch ExportCoordinatorError.exportDeferred {
      return .deferred(DeferredExportSummary(range: range))
    }
  }
}

enum ExportRunResult: Equatable {
  case exported(ExportSummary)
  case deferred(DeferredExportSummary)

  var intentDialog: String {
    switch self {
    case .exported(let summary):
      summary.intentDialog
    case .deferred(let summary):
      summary.intentDialog
    }
  }
}

struct DeferredExportSummary: Equatable {
  let range: WeekRange

  var intentDialog: String {
    "Queued Health data for \(range.displayLabel). Hem will retry when the app next opens after unlock."
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
