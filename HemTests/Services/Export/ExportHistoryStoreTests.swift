import XCTest

@testable import Hem

final class ExportHistoryStoreTests: XCTestCase {
  private var temporaryDirectory: URL!

  override func setUpWithError() throws {
    temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
  }

  override func tearDownWithError() throws {
    if let temporaryDirectory,
      FileManager.default.fileExists(atPath: temporaryDirectory.path)
    {
      try FileManager.default.removeItem(at: temporaryDirectory)
    }
  }

  func testRecordsRoundTripNewestFirst() throws {
    let store = ExportHistoryStore(baseURL: temporaryDirectory)
    let older = try record(requestedAt: VitalsTestFixture.date("2026-06-24T12:00:00+01:00"))
    let newer = try record(requestedAt: VitalsTestFixture.date("2026-06-25T12:00:00+01:00"))

    try store.saveRecords([older, newer])

    XCTAssertEqual(try store.loadRecords().map(\.id), [newer.id, older.id])
  }

  func testQueuedPayloadRoundTripAndDelete() throws {
    let store = ExportHistoryStore(baseURL: temporaryDirectory)
    let payload = try VitalsTestFixture.payload()

    try store.savePayload(payload, named: "payload.json")
    XCTAssertEqual(try store.loadPayload(named: "payload.json"), payload)

    try store.deletePayload(named: "payload.json")
    XCTAssertThrowsError(try store.loadPayload(named: "payload.json"))
  }

  private func record(requestedAt: Date) throws -> ExportRecord {
    ExportRecord(
      id: UUID(),
      range: try VitalsTestFixture.previousFullWeek(),
      mode: .manual,
      metrics: ExportMetricCategory.allCases,
      status: .succeeded,
      destinationHost: "hem-web.local",
      endpointURLString: "https://hem-web.local/apple-health/import",
      requestedAt: requestedAt,
      startedAt: requestedAt,
      completedAt: requestedAt,
      attemptCount: 1,
      counts: .empty,
      retrySourceID: nil,
      payloadFileName: nil,
      errorMessage: nil,
      errorCode: nil,
      httpStatus: 201,
      serverResponseSummary: nil
    )
  }
}

final class ExportCoordinatorHistoryTests: XCTestCase {
  func testDeleteRecordRemovesRecordAndQueuedPayload() throws {
    let queued = try record(
      requestedAt: VitalsTestFixture.date("2026-06-25T12:00:00+01:00"),
      payloadFileName: "queued.json"
    )
    let succeeded = try record(requestedAt: VitalsTestFixture.date("2026-06-24T12:00:00+01:00"))
    let store = MockExportHistoryStore(records: [queued, succeeded])
    let coordinator = ExportCoordinator(historyStore: store)

    try coordinator.deleteRecord(id: queued.id)

    XCTAssertEqual(store.records, [succeeded])
    XCTAssertEqual(store.deletedPayloads, ["queued.json"])
  }

  func testDeleteMissingRecordThrows() throws {
    let store = MockExportHistoryStore(records: [])
    let coordinator = ExportCoordinator(historyStore: store)

    XCTAssertThrowsError(try coordinator.deleteRecord(id: UUID())) { error in
      XCTAssertEqual(error as? ExportCoordinatorError, .recordNotFound)
    }
  }

  private func record(requestedAt: Date, payloadFileName: String? = nil) throws -> ExportRecord {
    ExportRecord(
      id: UUID(),
      range: try VitalsTestFixture.previousFullWeek(),
      mode: .manual,
      metrics: ExportMetricCategory.allCases,
      status: payloadFileName == nil ? .succeeded : .queued,
      destinationHost: "hem-web.local",
      endpointURLString: "https://hem-web.local/apple-health/import",
      requestedAt: requestedAt,
      startedAt: requestedAt,
      completedAt: requestedAt,
      attemptCount: 1,
      counts: .empty,
      retrySourceID: nil,
      payloadFileName: payloadFileName,
      errorMessage: nil,
      errorCode: nil,
      httpStatus: payloadFileName == nil ? 201 : nil,
      serverResponseSummary: nil
    )
  }
}

final class MetricSelectionStoreTests: XCTestCase {
  func testDefaultsToAllMetrics() {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = MetricSelectionStore(userDefaults: defaults)

    XCTAssertEqual(store.load(), Set(ExportMetricCategory.allCases))
  }

  func testSavesSelectedMetrics() {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = MetricSelectionStore(userDefaults: defaults)
    let metrics: Set<ExportMetricCategory> = [.steps, .sleep]

    store.save(metrics)

    XCTAssertEqual(store.load(), metrics)
  }
}

final class ExportDateRangeStoreTests: XCTestCase {
  func testDefaultsToProvidedRange() throws {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = ExportDateRangeStore(userDefaults: defaults)
    let range = try VitalsTestFixture.previousFullWeek()

    let dates = store.load(defaultRange: range)

    XCTAssertEqual(dates.startDate, range.start)
    XCTAssertEqual(
      dates.throughDate,
      Calendar.vitalsDefault.date(byAdding: .day, value: -1, to: range.end)
    )
  }

  func testSavesSelectedDateRange() throws {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = ExportDateRangeStore(userDefaults: defaults)
    let range = try VitalsTestFixture.previousFullWeek()
    let startDate = try VitalsTestFixture.date("2026-06-10T09:00:00+01:00")
    let throughDate = try VitalsTestFixture.date("2026-06-12T09:00:00+01:00")

    store.save(startDate: startDate, throughDate: throughDate)

    let dates = store.load(defaultRange: range)
    XCTAssertEqual(dates.startDate, startDate)
    XCTAssertEqual(dates.throughDate, throughDate)
  }

  func testInvalidSavedDateRangeFallsBackToDefault() throws {
    let suiteName = UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = ExportDateRangeStore(userDefaults: defaults)
    let range = try VitalsTestFixture.previousFullWeek()
    let startDate = try VitalsTestFixture.date("2026-06-12T09:00:00+01:00")
    let throughDate = try VitalsTestFixture.date("2026-06-10T09:00:00+01:00")

    store.save(startDate: startDate, throughDate: throughDate)

    let dates = store.load(defaultRange: range)
    XCTAssertEqual(dates.startDate, range.start)
    XCTAssertEqual(
      dates.throughDate,
      Calendar.vitalsDefault.date(byAdding: .day, value: -1, to: range.end)
    )
  }
}

private final class MockExportHistoryStore: ExportHistoryStoring {
  var records: [ExportRecord]
  var deletedPayloads: [String] = []

  init(records: [ExportRecord]) {
    self.records = records
  }

  func loadRecords() throws -> [ExportRecord] {
    records
  }

  func saveRecords(_ records: [ExportRecord]) throws {
    self.records = records
  }

  func savePayload(_ payload: ExportPayload, named fileName: String) throws {}

  func loadPayload(named fileName: String) throws -> ExportPayload {
    throw ExportCoordinatorError.recordNotFound
  }

  func deletePayload(named fileName: String) throws {
    deletedPayloads.append(fileName)
  }

  func deleteAll() throws {
    records = []
  }
}
