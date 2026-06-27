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
