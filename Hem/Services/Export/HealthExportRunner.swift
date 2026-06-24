import Foundation

struct HealthExportRunner {
  private let configurationStore: HemWebConfigurationStore
  private let exportService: HealthExportService
  private let client: HemWebClient

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: HealthExportService = HealthExportService(),
    client: HemWebClient = HemWebClient()
  ) {
    self.configurationStore = configurationStore
    self.exportService = exportService
    self.client = client
  }

  func exportPreviousFullWeek() async throws -> ExportSummary {
    let range = WeekRange.previousFullWeek()
    return try await export(range: range)
  }

  func export(range: WeekRange) async throws -> ExportSummary {
    let configuration = try configurationStore.load()
    let payload = try await exportService.makePayload(for: range)
    try await client.post(
      payload: payload, endpoint: configuration.endpoint,
      bearerToken: configuration.bearerToken)

    return ExportSummary(
      range: range,
      destinationHost: configuration.endpoint.host,
      dailyMetricCount: payload.dailyMetrics.count,
      sampleCount: payload.samples.count,
      workoutCount: payload.workouts.count,
      sleepSampleCount: payload.sleep.count
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
