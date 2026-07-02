import Foundation

struct ExportCoordinator {
  private let configurationStore: HemWebConfigurationStore
  private let exportService: HealthExportService
  private let client: HemWebClient
  private let historyStore: any ExportHistoryStoring
  private let checkpointStore: ExportCheckpointStore
  private let uuid: () -> UUID
  private let now: () -> Date

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: HealthExportService = HealthExportService(),
    client: HemWebClient = HemWebClient(),
    historyStore: any ExportHistoryStoring = ExportHistoryStore(),
    checkpointStore: ExportCheckpointStore = ExportCheckpointStore(),
    uuid: @escaping () -> UUID = UUID.init,
    now: @escaping () -> Date = Date.init
  ) {
    self.configurationStore = configurationStore
    self.exportService = exportService
    self.client = client
    self.historyStore = historyStore
    self.checkpointStore = checkpointStore
    self.uuid = uuid
    self.now = now
  }

  func records() throws -> [ExportRecord] {
    try historyStore.loadRecords()
  }

  func deleteRecord(id: UUID) throws {
    var records = try historyStore.loadRecords()
    guard let index = records.firstIndex(where: { $0.id == id }) else {
      throw ExportCoordinatorError.recordNotFound
    }

    let record = records.remove(at: index)
    if let payloadFileName = record.payloadFileName {
      try historyStore.deletePayload(named: payloadFileName)
    }

    try historyStore.saveRecords(records)
  }

  func prepare(
    range: WeekRange,
    mode: ExportMode = .manual,
    metrics: Set<ExportMetricCategory>
  ) async throws -> ExportDraft {
    let configuration = try configurationStore.load()
    let orderedMetrics = ordered(metrics)
    let payload = try await exportService.makePayload(for: range, including: metrics)
    let counts = ExportCounts(payload: payload, range: range)
    return ExportDraft(
      range: range,
      mode: mode,
      metrics: orderedMetrics,
      destinationHost: configuration.endpoint.host,
      endpointURLString: configuration.endpoint.importURL.absoluteString,
      payload: payload,
      counts: counts,
      warnings: warnings(for: payload, selectedMetrics: metrics)
    )
  }

  func send(_ draft: ExportDraft, retrySourceID: UUID? = nil) async throws -> ExportSummary {
    let configuration = try configurationStore.load()
    var records = try historyStore.loadRecords()
    var record = makeRecord(from: draft, configuration: configuration, retrySourceID: retrySourceID)
    records.insert(record, at: 0)
    try historyStore.saveRecords(records)

    do {
      let responseSummary = try await client.post(
        payload: draft.payload,
        endpoint: configuration.endpoint,
        bearerToken: configuration.bearerToken
      )
      record.status = .succeeded
      record.completedAt = now()
      record.httpStatus = responseSummary.statusCode
      record.serverResponseSummary = responseSummary.bodySummary
      record.errorMessage = nil
      checkpointStore.saveLastSuccessEnd(draft.range.end)
    } catch {
      record.completedAt = now()
      record.errorMessage = ExportErrorPresentation.message(for: error)
      record.errorCode = String(describing: type(of: error))

      if shouldQueue(error) {
        let payloadFileName = "\(record.id.uuidString).json"
        try historyStore.savePayload(draft.payload, named: payloadFileName)
        record.status = .queued
        record.payloadFileName = payloadFileName
      } else {
        record.status = .failed
      }

      try replace(record, in: &records)
      try historyStore.saveRecords(records)
      throw error
    }

    try replace(record, in: &records)
    try historyStore.saveRecords(records)
    return ExportSummary(
      range: draft.range,
      destinationHost: draft.destinationHost,
      dailyMetricCount: draft.counts.dailyMetricCount,
      sampleCount: draft.counts.sampleCount,
      workoutCount: draft.counts.workoutCount,
      sleepSampleCount: draft.counts.sleepSampleCount
    )
  }

  func export(
    range: WeekRange,
    mode: ExportMode = .manual,
    metrics: Set<ExportMetricCategory>
  ) async throws -> ExportSummary {
    let draft: ExportDraft
    do {
      draft = try await prepare(range: range, mode: mode, metrics: metrics)
    } catch {
      try? recordPreparationFailure(range: range, mode: mode, metrics: metrics, error: error)
      throw error
    }

    return try await send(draft)
  }

  func incrementalRange(calendar: Calendar = .vitalsDefault) -> WeekRange? {
    guard let lastSuccessEnd = checkpointStore.loadLastSuccessEnd() else {
      return nil
    }

    let start = calendar.startOfDay(for: lastSuccessEnd)
    let end = calendar.startOfDay(for: now())
    guard start < end else {
      return nil
    }

    return WeekRange(start: start, end: end, calendar: calendar, kind: "sinceLastSuccess")
  }

  func exportSinceLastSuccess(metrics: Set<ExportMetricCategory>) async throws -> ExportSummary {
    guard let range = incrementalRange() else {
      throw WeekRangeError.invalidDateRange
    }

    return try await export(range: range, mode: .incremental, metrics: metrics)
  }

  func retry(recordID: UUID) async throws -> ExportSummary {
    let records = try historyStore.loadRecords()
    guard let record = records.first(where: { $0.id == recordID }) else {
      throw ExportCoordinatorError.recordNotFound
    }

    if let payloadFileName = record.payloadFileName {
      let configuration = try configurationStore.load()
      let payload = try historyStore.loadPayload(named: payloadFileName)
      let draft = ExportDraft(
        range: record.range,
        mode: .retry,
        metrics: record.metrics,
        destinationHost: configuration.endpoint.host,
        endpointURLString: configuration.endpoint.importURL.absoluteString,
        payload: payload,
        counts: ExportCounts(payload: payload, range: record.range),
        warnings: warnings(for: payload, selectedMetrics: Set(record.metrics))
      )
      return try await send(draft, retrySourceID: record.id)
    }

    let draft = try await prepare(
      range: record.range,
      mode: .retry,
      metrics: Set(record.metrics)
    )
    return try await send(draft, retrySourceID: record.id)
  }

  func drainQueue() async {
    guard let records = try? historyStore.loadRecords() else {
      return
    }

    for record in records.reversed() where record.status == .queued {
      _ = try? await retry(recordID: record.id)
    }
  }

  func diagnostics(for recordID: UUID) throws -> ExportDiagnosticsBundle {
    let records = try historyStore.loadRecords()
    guard let record = records.first(where: { $0.id == recordID }) else {
      throw ExportCoordinatorError.recordNotFound
    }

    let lines = [
      "Hem Export Diagnostics",
      "Status: \(record.status.rawValue)",
      "Mode: \(record.mode.rawValue)",
      "Range: \(record.range.displayLabel)",
      "Destination: \(record.destinationHost)",
      "Endpoint: \(record.endpointURLString)",
      "Requested: \(record.requestedAt)",
      "Completed: \(record.completedAt.map(String.init(describing:)) ?? "Not completed")",
      "Attempts: \(record.attemptCount)",
      "Counts: days \(record.counts.dayCount), daily \(record.counts.dailyMetricCount), samples \(record.counts.sampleCount), workouts \(record.counts.workoutCount), sleep \(record.counts.sleepSampleCount)",
      "Error: \(record.errorMessage ?? "None")",
      "Error Code: \(record.errorCode ?? "None")",
      "HTTP Status: \(record.httpStatus.map(String.init) ?? "None")",
      "Server Response: \(record.serverResponseSummary ?? "None")",
    ]

    return ExportDiagnosticsBundle(text: lines.joined(separator: "\n"))
  }

  private func makeRecord(
    from draft: ExportDraft,
    configuration: HemWebConfiguration,
    retrySourceID: UUID?
  ) -> ExportRecord {
    let date = now()
    return ExportRecord(
      id: uuid(),
      range: draft.range,
      mode: draft.mode,
      metrics: draft.metrics,
      status: .sending,
      destinationHost: configuration.endpoint.host,
      endpointURLString: configuration.endpoint.importURL.absoluteString,
      requestedAt: date,
      startedAt: date,
      completedAt: nil,
      attemptCount: retrySourceID == nil ? 1 : 2,
      counts: draft.counts,
      retrySourceID: retrySourceID,
      payloadFileName: nil,
      errorMessage: nil,
      errorCode: nil,
      httpStatus: nil,
      serverResponseSummary: nil
    )
  }

  private func recordPreparationFailure(
    range: WeekRange,
    mode: ExportMode,
    metrics: Set<ExportMetricCategory>,
    error: Error
  ) throws {
    let requestedAt = now()
    let destination = destinationSnapshot()
    let record = ExportRecord(
      id: uuid(),
      range: range,
      mode: mode,
      metrics: ordered(metrics),
      status: .failed,
      destinationHost: destination.host,
      endpointURLString: destination.endpointURLString,
      requestedAt: requestedAt,
      startedAt: requestedAt,
      completedAt: requestedAt,
      attemptCount: 1,
      counts: .empty,
      retrySourceID: nil,
      payloadFileName: nil,
      errorMessage: ExportErrorPresentation.message(for: error),
      errorCode: String(describing: type(of: error)),
      httpStatus: nil,
      serverResponseSummary: nil
    )

    var records = try historyStore.loadRecords()
    records.insert(record, at: 0)
    try historyStore.saveRecords(records)
  }

  private func destinationSnapshot() -> (host: String, endpointURLString: String) {
    let endpointText = configurationStore.loadEndpointText()
    guard let endpoint = try? HemWebEndpoint(text: endpointText) else {
      return ("Not configured", endpointText)
    }

    return (endpoint.host, endpoint.importURL.absoluteString)
  }

  private func replace(_ record: ExportRecord, in records: inout [ExportRecord]) throws {
    guard let index = records.firstIndex(where: { $0.id == record.id }) else {
      throw ExportCoordinatorError.recordNotFound
    }

    records[index] = record
  }

  private func ordered(_ metrics: Set<ExportMetricCategory>) -> [ExportMetricCategory] {
    ExportMetricCategory.allCases.filter(metrics.contains)
  }

  private func warnings(
    for payload: ExportPayload,
    selectedMetrics: Set<ExportMetricCategory>
  ) -> [String] {
    var warnings: [String] = []
    if selectedMetrics.contains(.sleep), payload.sleep.isEmpty {
      warnings.append(
        "No sleep records found; data may be missing or permission may not be granted.")
    }
    if selectedMetrics.contains(.workouts), payload.workouts.isEmpty {
      warnings.append("No workouts found; data may be missing or permission may not be granted.")
    }
    if selectedMetrics.contains(.heart),
      !payload.samples.contains(where: { $0.type != "bodyMass" })
    {
      warnings.append(
        "No heart samples found; data may be missing or permission may not be granted.")
    }
    if selectedMetrics.contains(.bodyMass),
      !payload.samples.contains(where: { $0.type == "bodyMass" })
    {
      warnings.append(
        "No body mass samples found; data may be missing or permission may not be granted.")
    }
    if selectedMetrics.contains(where: { [.steps, .energy, .exercise, .distance].contains($0) }),
      payload.dailyMetrics.isEmpty
    {
      warnings.append(
        "No daily metrics found; data may be missing or permission may not be granted.")
    }
    return warnings
  }

  private func shouldQueue(_ error: Error) -> Bool {
    if let urlError = error as? URLError {
      switch urlError.code {
      case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
        .timedOut:
        return true
      default:
        return false
      }
    }

    return false
  }
}

enum ExportCoordinatorError: LocalizedError, Equatable {
  case recordNotFound

  var errorDescription: String? {
    switch self {
    case .recordNotFound:
      "The export record could not be found."
    }
  }
}
