import Foundation
import HealthKit

struct ExportCoordinator {
  private static let deferredHealthAccessMessage =
    "Health access is not available while the iPhone is locked. Hem will retry after unlock."

  private let configurationStore: HemWebConfigurationStore
  private let exportService: any HealthExportServicing
  private let client: HemWebClient
  private let historyStore: any ExportHistoryStoring
  private let checkpointStore: ExportCheckpointStore
  private let lock: ExportLock
  private let uuid: () -> UUID
  private let now: () -> Date

  init(
    configurationStore: HemWebConfigurationStore = HemWebConfigurationStore(),
    exportService: any HealthExportServicing = HealthExportService(),
    client: HemWebClient = HemWebClient(),
    historyStore: any ExportHistoryStoring = ExportHistoryStore(),
    checkpointStore: ExportCheckpointStore = ExportCheckpointStore(),
    lock: ExportLock = .shared,
    uuid: @escaping () -> UUID = UUID.init,
    now: @escaping () -> Date = Date.init
  ) {
    self.configurationStore = configurationStore
    self.exportService = exportService
    self.client = client
    self.historyStore = historyStore
    self.checkpointStore = checkpointStore
    self.lock = lock
    self.uuid = uuid
    self.now = now
  }

  func records() throws -> [ExportRecord] {
    try historyStore.loadRecords()
  }

  func deleteRecord(id: UUID) async throws {
    try await lock.withExclusiveAccess {
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
  }

  func prepare(
    range: WeekRange,
    mode: ExportMode = .manual,
    metrics: Set<ExportMetricCategory>
  ) async throws -> ExportDraft {
    let configuration = try configurationStore.load()
    let payload = try await exportService.makePayload(for: range, including: metrics)
    return makeDraft(
      range: range,
      mode: mode,
      metrics: metrics,
      payload: payload,
      configuration: configuration
    )
  }

  func send(_ draft: ExportDraft) async throws -> ExportSummary {
    try await lock.withExclusiveAccess {
      try await deliver(draft, as: newRecord(for: draft))
    }
  }

  func export(
    range: WeekRange,
    mode: ExportMode = .manual,
    metrics: Set<ExportMetricCategory>
  ) async throws -> ExportSummary {
    try await lock.withExclusiveAccess {
      let draft: ExportDraft
      do {
        draft = try await prepare(range: range, mode: mode, metrics: metrics)
      } catch {
        let isDeferred = mode == .shortcut && isHealthDatabaseInaccessible(error)
        try? recordPreparationFailure(
          range: range,
          mode: mode,
          metrics: metrics,
          error: error,
          isDeferred: isDeferred
        )
        throw isDeferred ? ExportCoordinatorError.exportDeferred : error
      }

      return try await deliver(draft, as: newRecord(for: draft))
    }
  }

  func incrementalRange(calendar: Calendar = .exportDefault) -> WeekRange? {
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

  /// Retries a queued record in place, or sends a failed record again as a new history record.
  func retry(recordID: UUID) async throws -> ExportSummary {
    try await lock.withExclusiveAccess {
      let record = try loadRecord(id: recordID)
      if record.status == .queued {
        return try await completeQueuedRecord(record)
      }

      let draft = try await draft(for: record, mode: .retry)
      var retryRecord = newRecord(for: draft)
      retryRecord.attemptCount = 2
      retryRecord.retrySourceID = record.id
      return try await deliver(draft, as: retryRecord)
    }
  }

  func drainQueue() async {
    await lock.withExclusiveAccess {
      guard let records = try? historyStore.loadRecords() else {
        return
      }

      for record in records.reversed()
      where record.status == .queued && (record.nextRetryAt.map { $0 <= now() } ?? true) {
        _ = try? await completeQueuedRecord(record)
      }
    }
  }

  func diagnostics(for recordID: UUID) throws -> String {
    let record = try loadRecord(id: recordID)
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
      "Local Counts: days \(record.counts.dayCount), daily rows \(record.counts.dailyMetricCount), samples \(record.counts.sampleCount), category samples \(record.counts.categorySampleCount), workouts \(record.counts.workoutCount), sleep \(record.counts.sleepSampleCount)",
      "Error: \(record.errorMessage ?? "None")",
      "Error Code: \(record.errorCode ?? "None")",
      "HTTP Status: \(record.httpStatus.map(String.init) ?? "None")",
      "Server Import ID: \(record.serverImportID.map(String.init) ?? "None")",
      "Server Import Status: \(record.serverImportStatus?.rawValue ?? "None")",
      "Server Counts: \(serverCountsDescription(record.serverCounts))",
      "Next Retry: \(record.nextRetryAt.map(String.init(describing:)) ?? "None")",
    ]

    return lines.joined(separator: "\n")
  }

  /// Sends the draft's payload and saves the outcome to `record`.
  ///
  /// Retryable failures keep the payload on disk and leave the record queued; a later success
  /// removes any saved payload.
  private func deliver(_ draft: ExportDraft, as record: ExportRecord) async throws
    -> ExportSummary
  {
    let configuration = try configurationStore.load()
    var record = record
    record.status = .sending
    record.errorMessage = nil
    record.errorCode = nil
    record.httpStatus = nil
    record.serverImportID = nil
    record.serverImportStatus = nil
    record.serverCounts = nil
    record.nextRetryAt = nil
    try save(record)

    let response: HemWebResponseSummary
    do {
      response = try await client.post(
        payload: draft.payload,
        endpoint: configuration.endpoint,
        bearerToken: configuration.bearerToken
      )
    } catch {
      record.completedAt = now()
      record.errorMessage = ExportErrorPresentation.message(for: error)
      record.errorCode = errorCode(for: error)
      record.httpStatus = (error as? HemWebClientError)?.statusCode
      record.nextRetryAt = nextRetryDate(for: error)

      if shouldQueue(error) {
        if record.payloadFileName == nil {
          let payloadFileName = "\(record.id.uuidString).json"
          try historyStore.savePayload(draft.payload, named: payloadFileName)
          record.payloadFileName = payloadFileName
        }
        record.status = .queued
      } else {
        record.status = .failed
      }

      try save(record)
      throw error
    }

    record.status = .succeeded
    record.completedAt = now()
    record.httpStatus = response.statusCode
    record.serverImportID = response.importResult?.importId
    record.serverImportStatus = response.importResult?.status
    record.serverCounts = response.importResult?.counts
    if let payloadFileName = record.payloadFileName {
      try? historyStore.deletePayload(named: payloadFileName)
      record.payloadFileName = nil
    }
    checkpointStore.advanceLastSuccessEnd(to: min(draft.range.end, now()))
    try save(record)

    return ExportSummary(
      range: draft.range,
      destinationHost: draft.destinationHost,
      serverImportStatus: record.serverImportStatus
    )
  }

  private func completeQueuedRecord(_ record: ExportRecord) async throws -> ExportSummary {
    var record = record
    let draft: ExportDraft
    do {
      draft = try await self.draft(for: record, mode: record.mode)
    } catch {
      let isDeferred = isHealthDatabaseInaccessible(error)
      record.status = isDeferred ? .queued : .failed
      record.completedAt = isDeferred ? nil : now()
      record.errorMessage =
        isDeferred ? Self.deferredHealthAccessMessage : ExportErrorPresentation.message(for: error)
      record.errorCode = errorCode(for: error)
      try? save(record)
      throw isDeferred ? ExportCoordinatorError.exportDeferred : error
    }

    record.startedAt = now()
    record.completedAt = nil
    record.attemptCount += 1
    record.destinationHost = draft.destinationHost
    record.endpointURLString = draft.endpointURLString
    record.counts = draft.counts
    return try await deliver(draft, as: record)
  }

  /// Rebuilds a record's draft from its saved payload, or from HealthKit when none was saved.
  private func draft(for record: ExportRecord, mode: ExportMode) async throws -> ExportDraft {
    guard let payloadFileName = record.payloadFileName else {
      return try await prepare(range: record.range, mode: mode, metrics: Set(record.metrics))
    }

    let configuration = try configurationStore.load()
    return makeDraft(
      range: record.range,
      mode: mode,
      metrics: Set(record.metrics),
      payload: try historyStore.loadPayload(named: payloadFileName),
      configuration: configuration
    )
  }

  private func makeDraft(
    range: WeekRange,
    mode: ExportMode,
    metrics: Set<ExportMetricCategory>,
    payload: ExportPayload,
    configuration: HemWebConfiguration
  ) -> ExportDraft {
    ExportDraft(
      range: range,
      mode: mode,
      metrics: ordered(metrics),
      destinationHost: configuration.endpoint.host,
      endpointURLString: configuration.endpoint.importURL.absoluteString,
      payload: payload,
      counts: ExportCounts(payload: payload, range: range),
      warnings: warnings(for: payload, selectedMetrics: metrics)
    )
  }

  private func newRecord(for draft: ExportDraft) -> ExportRecord {
    let date = now()
    return ExportRecord(
      id: uuid(),
      range: draft.range,
      mode: draft.mode,
      metrics: draft.metrics,
      status: .sending,
      destinationHost: draft.destinationHost,
      endpointURLString: draft.endpointURLString,
      requestedAt: date,
      startedAt: date,
      completedAt: nil,
      attemptCount: 1,
      counts: draft.counts,
      retrySourceID: nil,
      payloadFileName: nil,
      errorMessage: nil,
      errorCode: nil,
      httpStatus: nil
    )
  }

  private func recordPreparationFailure(
    range: WeekRange,
    mode: ExportMode,
    metrics: Set<ExportMetricCategory>,
    error: Error,
    isDeferred: Bool
  ) throws {
    let requestedAt = now()
    let destination = destinationSnapshot()
    try save(
      ExportRecord(
        id: uuid(),
        range: range,
        mode: mode,
        metrics: ordered(metrics),
        status: isDeferred ? .queued : .failed,
        destinationHost: destination.host,
        endpointURLString: destination.endpointURLString,
        requestedAt: requestedAt,
        startedAt: requestedAt,
        completedAt: isDeferred ? nil : requestedAt,
        attemptCount: 1,
        counts: .empty,
        retrySourceID: nil,
        payloadFileName: nil,
        errorMessage: isDeferred
          ? Self.deferredHealthAccessMessage : ExportErrorPresentation.message(for: error),
        errorCode: errorCode(for: error),
        httpStatus: nil
      )
    )
  }

  private func loadRecord(id: UUID) throws -> ExportRecord {
    guard let record = try historyStore.loadRecords().first(where: { $0.id == id }) else {
      throw ExportCoordinatorError.recordNotFound
    }
    return record
  }

  /// Replaces the stored record with the same ID, or inserts it as the newest record.
  private func save(_ record: ExportRecord) throws {
    var records = try historyStore.loadRecords()
    if let index = records.firstIndex(where: { $0.id == record.id }) {
      records[index] = record
    } else {
      records.insert(record, at: 0)
    }
    try historyStore.saveRecords(records)
  }

  private func destinationSnapshot() -> (host: String, endpointURLString: String) {
    let endpointText = configurationStore.loadEndpointText()
    guard let endpoint = try? HemWebEndpoint(text: endpointText) else {
      return ("Not configured", endpointText)
    }

    return (endpoint.host, endpoint.importURL.absoluteString)
  }

  private func ordered(_ metrics: Set<ExportMetricCategory>) -> [ExportMetricCategory] {
    ExportMetricCategory.allCases.filter(metrics.contains)
  }

  private func warnings(
    for payload: ExportPayload,
    selectedMetrics: Set<ExportMetricCategory>
  ) -> [String] {
    let categoriesWithData = HealthMetricDefinitions.categoriesWithData(in: payload)
    let emptyCategories = ordered(selectedMetrics.subtracting(categoriesWithData))
    guard !emptyCategories.isEmpty else {
      return []
    }

    let titles = emptyCategories.map(\.title).joined(separator: ", ")
    return [
      "No data found for \(titles). Data may be missing or Health access may not be granted."
    ]
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

    if let statusCode = (error as? HemWebClientError)?.statusCode {
      return statusCode == 429 || (500..<600).contains(statusCode)
    }

    return false
  }

  private func nextRetryDate(for error: Error) -> Date? {
    guard let retryAfter = (error as? HemWebClientError)?.retryAfter else {
      return nil
    }
    return now().addingTimeInterval(retryAfter)
  }

  private func serverCountsDescription(_ counts: HemWebImportCounts?) -> String {
    guard let counts else {
      return "None"
    }
    return
      "daily facts \(counts.dailyMetrics), samples \(counts.samples), category samples \(counts.categorySamples), workouts \(counts.workouts), sleep \(counts.sleep)"
  }

  private func isHealthDatabaseInaccessible(_ error: Error) -> Bool {
    (error as? HKError)?.code == .errorDatabaseInaccessible
  }

  private func errorCode(for error: Error) -> String {
    error is HKError ? "HKError" : String(describing: type(of: error))
  }
}

/// Serialises export operations that read, modify, and write export history.
///
/// The app UI, queue draining, and App Shortcuts each create their own `ExportCoordinator`, so
/// the lock is shared to stop overlapping runs from sending the same queued export twice or
/// overwriting each other's history updates.
final class ExportLock: Sendable {
  static let shared = ExportLock()

  private let state = State()

  func withExclusiveAccess<T>(_ operation: () async throws -> T) async rethrows -> T {
    await state.acquire()
    do {
      let value = try await operation()
      await state.release()
      return value
    } catch {
      await state.release()
      throw error
    }
  }

  private actor State {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
      guard isLocked else {
        isLocked = true
        return
      }
      await withCheckedContinuation { waiters.append($0) }
    }

    func release() {
      if waiters.isEmpty {
        isLocked = false
      } else {
        waiters.removeFirst().resume()
      }
    }
  }
}

enum ExportCoordinatorError: LocalizedError, Equatable {
  case recordNotFound
  case exportDeferred

  var errorDescription: String? {
    switch self {
    case .recordNotFound:
      "The export record could not be found."
    case .exportDeferred:
      "Queued export until Health data is available after unlock."
    }
  }
}

protocol HealthExportServicing {
  func makePayload(
    for range: WeekRange,
    including metrics: Set<ExportMetricCategory>
  ) async throws -> ExportPayload
}

extension HealthExportService: HealthExportServicing {}
