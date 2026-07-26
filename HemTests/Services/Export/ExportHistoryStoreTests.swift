import Foundation
import HealthKit
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

  func testLegacyRecordWithoutCategoryOrServerFieldsStillDecodes() throws {
    let record = try record(requestedAt: VitalsTestFixture.date("2026-06-24T12:00:00+01:00"))
    let encoded = try JSONEncoder.exportStore.encode([record])
    var records = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [[String: Any]])
    var counts = try XCTUnwrap(records[0]["counts"] as? [String: Any])
    counts.removeValue(forKey: "categorySampleCount")
    records[0]["counts"] = counts
    records[0].removeValue(forKey: "serverImportID")
    records[0].removeValue(forKey: "serverImportStatus")
    records[0].removeValue(forKey: "serverCounts")
    records[0].removeValue(forKey: "nextRetryAt")

    let data = try JSONSerialization.data(withJSONObject: records)
    let decoded = try JSONDecoder.exportStore.decode([ExportRecord].self, from: data)

    XCTAssertEqual(decoded.first?.counts.categorySampleCount, 0)
    XCTAssertNil(decoded.first?.serverImportID)
    XCTAssertNil(decoded.first?.serverImportStatus)
    XCTAssertNil(decoded.first?.serverCounts)
    XCTAssertNil(decoded.first?.nextRetryAt)
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
  func testShortcutSendAddsHistoryRecord() async throws {
    let suiteName = UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let keychainStore = KeychainStore(service: "dev.tombell.hem.tests.\(UUID().uuidString)")
    defer { try? keychainStore.delete(account: "hemWebBearerToken") }

    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let configurationStore = HemWebConfigurationStore(
      userDefaults: defaults,
      keychainStore: keychainStore
    )
    try configurationStore.save(
      endpointText: endpoint.importURL.absoluteString,
      bearerToken: "token"
    )

    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: endpoint.importURL,
        statusCode: 201,
        httpVersion: nil,
        headerFields: nil)
    )
    let store = MockExportHistoryStore(records: [])
    let requestedAt = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let recordID = UUID()
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      client: HemWebClient(
        session: MockHTTPSession(data: Self.createdResponse, response: response)),
      historyStore: store,
      uuid: { recordID },
      now: { requestedAt }
    )
    let range = try VitalsTestFixture.previousFullWeek()
    let payload = try VitalsTestFixture.payload()
    let draft = ExportDraft(
      range: range,
      mode: .shortcut,
      metrics: ExportMetricCategory.allCases,
      destinationHost: endpoint.host,
      endpointURLString: endpoint.importURL.absoluteString,
      payload: payload,
      counts: ExportCounts(payload: payload, range: range),
      warnings: []
    )

    _ = try await coordinator.send(draft)

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.id, recordID)
    XCTAssertEqual(record.mode, .shortcut)
    XCTAssertEqual(record.status, .succeeded)
    XCTAssertEqual(record.httpStatus, 201)
    XCTAssertEqual(record.serverImportID, 42)
    XCTAssertEqual(record.serverImportStatus, .created)
    XCTAssertEqual(record.serverCounts?.categorySamples, 2)
  }

  func testShortcutPreparationFailureAddsHistoryRecord() async throws {
    let suiteName = UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let keychainStore = KeychainStore(service: "dev.tombell.hem.tests.\(UUID().uuidString)")
    defer { try? keychainStore.delete(account: "hemWebBearerToken") }

    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let configurationStore = HemWebConfigurationStore(
      userDefaults: defaults,
      keychainStore: keychainStore
    )
    try configurationStore.save(
      endpointText: endpoint.importURL.absoluteString,
      bearerToken: ""
    )

    let store = MockExportHistoryStore(records: [])
    let requestedAt = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let recordID = UUID()
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      historyStore: store,
      uuid: { recordID },
      now: { requestedAt }
    )
    let range = try VitalsTestFixture.previousFullWeek()

    do {
      _ = try await coordinator.export(range: range, mode: .shortcut, metrics: [.steps])
      XCTFail("Expected shortcut export to fail without a bearer token.")
    } catch {
      XCTAssertEqual(error as? HemWebClientError, .missingToken)
    }

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.id, recordID)
    XCTAssertEqual(record.mode, .shortcut)
    XCTAssertEqual(record.metrics, [.steps])
    XCTAssertEqual(record.status, .failed)
    XCTAssertEqual(record.destinationHost, endpoint.host)
    XCTAssertEqual(record.endpointURLString, endpoint.importURL.absoluteString)
    XCTAssertEqual(record.requestedAt, requestedAt)
    XCTAssertEqual(record.startedAt, requestedAt)
    XCTAssertEqual(record.completedAt, requestedAt)
    XCTAssertEqual(record.counts, .empty)
    XCTAssertEqual(record.errorMessage, HemWebClientError.missingToken.errorDescription)
    XCTAssertEqual(record.errorCode, "HemWebClientError")
    XCTAssertNil(record.httpStatus)
  }

  func testShortcutLockedHealthPreparationQueuesHistoryRecord() async throws {
    let deferredMessage =
      "Health access is not available while the iPhone is locked. Hem will retry after unlock."
    let suiteName = UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let keychainStore = KeychainStore(service: "dev.tombell.hem.tests.\(UUID().uuidString)")
    defer { try? keychainStore.delete(account: "hemWebBearerToken") }

    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let configurationStore = HemWebConfigurationStore(
      userDefaults: defaults,
      keychainStore: keychainStore
    )
    try configurationStore.save(
      endpointText: endpoint.importURL.absoluteString,
      bearerToken: "token"
    )

    let store = MockExportHistoryStore(records: [])
    let requestedAt = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let recordID = UUID()
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      exportService: MockHealthExportService { _, _ in
        throw HKError(.errorDatabaseInaccessible)
      },
      historyStore: store,
      uuid: { recordID },
      now: { requestedAt }
    )
    let range = try VitalsTestFixture.previousFullWeek()

    do {
      _ = try await coordinator.export(range: range, mode: .shortcut, metrics: [.steps])
      XCTFail("Expected shortcut export to defer while HealthKit is locked.")
    } catch {
      XCTAssertEqual(error as? ExportCoordinatorError, .exportDeferred)
    }

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.id, recordID)
    XCTAssertEqual(record.mode, .shortcut)
    XCTAssertEqual(record.metrics, [.steps])
    XCTAssertEqual(record.status, .queued)
    XCTAssertEqual(record.destinationHost, endpoint.host)
    XCTAssertEqual(record.endpointURLString, endpoint.importURL.absoluteString)
    XCTAssertEqual(record.requestedAt, requestedAt)
    XCTAssertEqual(record.startedAt, requestedAt)
    XCTAssertNil(record.completedAt)
    XCTAssertEqual(record.counts, .empty)
    XCTAssertEqual(record.errorMessage, deferredMessage)
    XCTAssertEqual(record.errorCode, "HKError")
    XCTAssertNil(record.payloadFileName)
    XCTAssertNil(record.httpStatus)
  }

  func testDrainQueueCompletesDeferredShortcutRecord() async throws {
    let deferredMessage =
      "Health access is not available while the iPhone is locked. Hem will retry after unlock."
    let suiteName = UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let keychainStore = KeychainStore(service: "dev.tombell.hem.tests.\(UUID().uuidString)")
    defer { try? keychainStore.delete(account: "hemWebBearerToken") }

    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let configurationStore = HemWebConfigurationStore(
      userDefaults: defaults,
      keychainStore: keychainStore
    )
    try configurationStore.save(
      endpointText: endpoint.importURL.absoluteString,
      bearerToken: "token"
    )

    let range = try VitalsTestFixture.previousFullWeek()
    let requestedAt = try VitalsTestFixture.date("2026-06-25T08:00:00+01:00")
    let completedAt = try VitalsTestFixture.date("2026-06-25T09:00:00+01:00")
    let recordID = UUID()
    let queued = ExportRecord(
      id: recordID,
      range: range,
      mode: .shortcut,
      metrics: [.steps],
      status: .queued,
      destinationHost: endpoint.host,
      endpointURLString: endpoint.importURL.absoluteString,
      requestedAt: requestedAt,
      startedAt: requestedAt,
      completedAt: nil,
      attemptCount: 1,
      counts: .empty,
      retrySourceID: nil,
      payloadFileName: nil,
      errorMessage: deferredMessage,
      errorCode: "HKError",
      httpStatus: nil,
      serverResponseSummary: nil
    )
    let payload = try VitalsTestFixture.payload()
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: endpoint.importURL,
        statusCode: 201,
        httpVersion: nil,
        headerFields: nil)
    )
    let store = MockExportHistoryStore(records: [queued])
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      exportService: MockHealthExportService { requestedRange, requestedMetrics in
        XCTAssertEqual(requestedRange, range)
        XCTAssertEqual(requestedMetrics, [.steps])
        return payload
      },
      client: HemWebClient(
        session: MockHTTPSession(data: Self.createdResponse, response: response)),
      historyStore: store,
      now: { completedAt }
    )

    await coordinator.drainQueue()

    XCTAssertEqual(store.records.count, 1)
    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.id, recordID)
    XCTAssertEqual(record.mode, .shortcut)
    XCTAssertEqual(record.status, .succeeded)
    XCTAssertEqual(record.attemptCount, 2)
    XCTAssertEqual(record.counts, ExportCounts(payload: payload, range: range))
    XCTAssertEqual(record.completedAt, completedAt)
    XCTAssertNil(record.errorMessage)
    XCTAssertNil(record.errorCode)
    XCTAssertNil(record.payloadFileName)
    XCTAssertEqual(record.httpStatus, 201)
    XCTAssertEqual(record.serverImportStatus, .created)
  }

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

  func testRateLimitedManualExportQueuesPayloadUntilRetryDate() async throws {
    let (configurationStore, endpoint) = try configuredStore()
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: endpoint.importURL,
        statusCode: 429,
        httpVersion: nil,
        headerFields: ["Retry-After": "120"])
    )
    let now = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let store = MockExportHistoryStore(records: [])
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      client: HemWebClient(
        session: MockHTTPSession(
          data: Self.errorResponse(category: "rate_limit", message: "Rate limit exceeded"),
          response: response
        ),
        now: { now }
      ),
      historyStore: store,
      now: { now }
    )
    let range = try VitalsTestFixture.previousFullWeek()
    let payload = try VitalsTestFixture.payload()
    let draft = ExportDraft(
      range: range,
      mode: .manual,
      metrics: [.steps],
      destinationHost: endpoint.host,
      endpointURLString: endpoint.importURL.absoluteString,
      payload: payload,
      counts: ExportCounts(payload: payload, range: range),
      warnings: []
    )

    do {
      _ = try await coordinator.send(draft)
      XCTFail("Expected rate-limited export to be queued.")
    } catch {
      XCTAssertEqual((error as? HemWebClientError)?.statusCode, 429)
    }

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.status, .queued)
    XCTAssertEqual(record.httpStatus, 429)
    XCTAssertEqual(record.nextRetryAt, now.addingTimeInterval(120))
    XCTAssertNotNil(record.payloadFileName)
    XCTAssertEqual(store.payloads.count, 1)
  }

  func testUnauthorizedManualExportFailsWithoutQueueingPayload() async throws {
    let (configurationStore, endpoint) = try configuredStore()
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: endpoint.importURL,
        statusCode: 401,
        httpVersion: nil,
        headerFields: nil)
    )
    let store = MockExportHistoryStore(records: [])
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      client: HemWebClient(
        session: MockHTTPSession(
          data: Self.errorResponse(category: "auth", message: "Unauthorized"),
          response: response
        )
      ),
      historyStore: store
    )
    let range = try VitalsTestFixture.previousFullWeek()
    let payload = try VitalsTestFixture.payload()
    let draft = ExportDraft(
      range: range,
      mode: .manual,
      metrics: [.steps],
      destinationHost: endpoint.host,
      endpointURLString: endpoint.importURL.absoluteString,
      payload: payload,
      counts: ExportCounts(payload: payload, range: range),
      warnings: []
    )

    do {
      _ = try await coordinator.send(draft)
      XCTFail("Expected unauthorized export to fail.")
    } catch {
      XCTAssertEqual((error as? HemWebClientError)?.statusCode, 401)
    }

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.status, .failed)
    XCTAssertEqual(record.httpStatus, 401)
    XCTAssertNil(record.payloadFileName)
    XCTAssertTrue(store.payloads.isEmpty)
  }

  func testDrainSkipsRateLimitedRecordBeforeRetryDate() async throws {
    let now = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let queued = try record(
      requestedAt: now,
      payloadFileName: "queued.json",
      nextRetryAt: now.addingTimeInterval(120)
    )
    let store = MockExportHistoryStore(
      records: [queued],
      payloads: ["queued.json": try VitalsTestFixture.payload()]
    )
    let coordinator = ExportCoordinator(historyStore: store, now: { now })

    await coordinator.drainQueue()

    XCTAssertEqual(store.records.first?.status, .queued)
    XCTAssertEqual(store.records.first?.attemptCount, 1)
    XCTAssertEqual(store.payloads.count, 1)
  }

  func testQueuedServerFailureRemainsQueuedForRetry() async throws {
    let (configurationStore, endpoint) = try configuredStore()
    let now = try VitalsTestFixture.date("2026-06-25T12:00:00+01:00")
    let queued = try record(
      requestedAt: now,
      payloadFileName: "queued.json"
    )
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: endpoint.importURL,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil)
    )
    let store = MockExportHistoryStore(
      records: [queued],
      payloads: ["queued.json": try VitalsTestFixture.payload()]
    )
    let coordinator = ExportCoordinator(
      configurationStore: configurationStore,
      client: HemWebClient(
        session: MockHTTPSession(
          data: Self.errorResponse(category: "server_error", message: "Import failed"),
          response: response
        )
      ),
      historyStore: store,
      now: { now }
    )

    do {
      _ = try await coordinator.retry(recordID: queued.id)
      XCTFail("Expected queued retry to fail.")
    } catch {
      XCTAssertEqual((error as? HemWebClientError)?.statusCode, 500)
    }

    let record = try XCTUnwrap(store.records.first)
    XCTAssertEqual(record.status, .queued)
    XCTAssertEqual(record.attemptCount, 2)
    XCTAssertEqual(record.httpStatus, 500)
    XCTAssertEqual(record.payloadFileName, "queued.json")
  }

  private func record(
    requestedAt: Date,
    payloadFileName: String? = nil,
    nextRetryAt: Date? = nil
  ) throws -> ExportRecord {
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
      serverResponseSummary: nil,
      nextRetryAt: nextRetryAt
    )
  }

  private func configuredStore() throws -> (HemWebConfigurationStore, HemWebEndpoint) {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let store = HemWebConfigurationStore(
      userDefaults: defaults,
      keychainStore: KeychainStore(service: "dev.tombell.hem.tests.\(UUID().uuidString)")
    )
    try store.save(
      endpointText: endpoint.importURL.absoluteString,
      bearerToken: "token"
    )
    return (store, endpoint)
  }

  private static func errorResponse(category: String, message: String) -> Data {
    Data(
      """
      {"ok":false,"error":{"category":"\(category)","message":"\(message)"}}
      """.utf8)
  }

  private static var createdResponse: Data {
    Data(
      """
      {
        "ok": true,
        "importId": 42,
        "status": "created",
        "counts": {
          "categorySamples": 2,
          "dailyMetrics": 4,
          "samples": 1,
          "sleep": 1,
          "workouts": 1
        }
      }
      """.utf8)
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
  var payloads: [String: ExportPayload]
  var deletedPayloads: [String] = []

  init(records: [ExportRecord], payloads: [String: ExportPayload] = [:]) {
    self.records = records
    self.payloads = payloads
  }

  func loadRecords() throws -> [ExportRecord] {
    records
  }

  func saveRecords(_ records: [ExportRecord]) throws {
    self.records = records
  }

  func savePayload(_ payload: ExportPayload, named fileName: String) throws {
    payloads[fileName] = payload
  }

  func loadPayload(named fileName: String) throws -> ExportPayload {
    guard let payload = payloads[fileName] else {
      throw ExportCoordinatorError.recordNotFound
    }
    return payload
  }

  func deletePayload(named fileName: String) throws {
    deletedPayloads.append(fileName)
    payloads.removeValue(forKey: fileName)
  }

  func deleteAll() throws {
    records = []
    payloads = [:]
  }
}

private struct MockHealthExportService: HealthExportServicing {
  let makePayloadHandler: (WeekRange, Set<ExportMetricCategory>) async throws -> ExportPayload

  func makePayload(
    for range: WeekRange,
    including metrics: Set<ExportMetricCategory>
  ) async throws -> ExportPayload {
    try await makePayloadHandler(range, metrics)
  }
}

private final class MockHTTPSession: HTTPSession {
  private let dataValue: Data
  private let responseValue: URLResponse

  init(data: Data, response: URLResponse) {
    dataValue = data
    responseValue = response
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    return (dataValue, responseValue)
  }
}
