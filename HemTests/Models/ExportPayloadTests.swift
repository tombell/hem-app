import XCTest

@testable import Hem

final class ExportPayloadTests: XCTestCase {
  func testPayloadEncodingUsesSchemaAndOmitsNilMetricFields() throws {
    let range = WeekRange.previousFullWeek(
      now: try VitalsTestFixture.date("2026-06-24T12:00:00+01:00"),
      calendar: .vitalsDefault
    )
    let payload = ExportPayload(
      source: VitalsTestFixture.source,
      generatedAt: try VitalsTestFixture.date("2026-06-24T12:15:00+01:00"),
      range: ExportPayload.RangeMetadata(weekRange: range),
      dailyMetrics: [
        ExportPayload.DailyMetric(
          date: "2026-06-15",
          steps: .init(value: 8421, unit: "count"),
          activeEnergy: nil,
          basalEnergy: nil,
          exerciseTime: nil,
          walkingRunningDistance: .init(value: 6.3, unit: "km"),
          cyclingDistance: nil,
          swimmingDistance: nil,
          swimmingStrokeCount: nil,
          flightsClimbed: nil
        )
      ],
      samples: [],
      workouts: [],
      sleep: []
    )

    let data = try ExportPayloadEncoding.encode(payload)
    let json = try XCTUnwrap(String(data: data, encoding: .utf8))
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let source = try XCTUnwrap(object["source"] as? [String: Any])
    let encodedRange = try XCTUnwrap(object["range"] as? [String: Any])

    XCTAssertEqual(object["schemaVersion"] as? Int, 1)
    XCTAssertEqual(source["bundleIdentifier"] as? String, "dev.tombell.hem")
    XCTAssertEqual(encodedRange["timeZone"] as? String, "Europe/London")
    XCTAssertFalse(json.contains("null"))
  }

  func testPayloadEncodingIncludesStableRecordAndDeviceIdentifiers() throws {
    let range = try VitalsTestFixture.previousFullWeek()
    let date = try VitalsTestFixture.date("2026-06-15T08:30:00+01:00")
    let payload = ExportPayload(
      source: VitalsTestFixture.source,
      generatedAt: date,
      range: ExportPayload.RangeMetadata(weekRange: range),
      dailyMetrics: [],
      samples: [
        .init(
          id: "quantity-id",
          type: "bodyMass",
          start: date,
          end: date.addingTimeInterval(60),
          value: 75,
          unit: "kg")
      ],
      categorySamples: [
        .init(
          id: "category-id",
          type: "mindfulSession",
          start: date,
          end: date.addingTimeInterval(300),
          value: "logged")
      ],
      workouts: [],
      sleep: [
        .init(
          id: "sleep-id",
          start: date,
          end: date.addingTimeInterval(3600),
          value: "asleepCore")
      ]
    )

    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: ExportPayloadEncoding.encode(payload))
        as? [String: Any])
    let source = try XCTUnwrap(object["source"] as? [String: Any])
    let samples = try XCTUnwrap(object["samples"] as? [[String: Any]])
    let categorySamples = try XCTUnwrap(object["categorySamples"] as? [[String: Any]])
    let sleep = try XCTUnwrap(object["sleep"] as? [[String: Any]])

    XCTAssertEqual(
      source["deviceIdentifier"] as? String,
      "00000000-0000-0000-0000-000000000001"
    )
    XCTAssertEqual(samples.first?["id"] as? String, "quantity-id")
    XCTAssertEqual(categorySamples.first?["id"] as? String, "category-id")
    XCTAssertEqual(sleep.first?["id"] as? String, "sleep-id")
  }

  func testLegacyPayloadWithoutIdentifiersStillDecodes() throws {
    let data = Data(
      """
      {
        "schemaVersion": 1,
        "source": {
          "app": "Hem",
          "bundleIdentifier": "dev.tombell.hem",
          "deviceName": "Legacy iPhone",
          "deviceSystemName": "iOS",
          "deviceSystemVersion": "18.0"
        },
        "generatedAt": "2026-06-16T12:00:00+01:00",
        "range": {
          "start": "2026-06-15T00:00:00+01:00",
          "end": "2026-06-16T00:00:00+01:00",
          "calendar": "gregorian",
          "timeZone": "Europe/London",
          "kind": "custom"
        },
        "dailyMetrics": [],
        "samples": [{
          "type": "bodyMass",
          "start": "2026-06-15T08:00:00+01:00",
          "end": "2026-06-15T08:01:00+01:00",
          "value": 75,
          "unit": "kg"
        }],
        "categorySamples": [{
          "type": "mindfulSession",
          "start": "2026-06-15T09:00:00+01:00",
          "end": "2026-06-15T09:05:00+01:00",
          "value": "logged"
        }],
        "workouts": [],
        "sleep": [{
          "start": "2026-06-15T22:00:00+01:00",
          "end": "2026-06-16T00:00:00+01:00",
          "value": "asleepCore"
        }]
      }
      """.utf8)

    let payload = try ExportDateFormatting.jsonDecoder.decode(ExportPayload.self, from: data)

    XCTAssertNil(payload.source.deviceIdentifier)
    XCTAssertNil(payload.samples.first?.id)
    XCTAssertNil(payload.categorySamples.first?.id)
    XCTAssertNil(payload.sleep.first?.id)
  }
}

final class ExportDeviceIdentifierStoreTests: XCTestCase {
  func testReusesPersistedIdentifier() throws {
    let keychain = MockKeychainStore(storedValue: "persisted-id")
    let store = ExportDeviceIdentifierStore(
      keychainStore: keychain,
      uuid: { UUID(uuidString: "00000000-0000-0000-0000-000000000002")! }
    )

    XCTAssertEqual(try store.identifier(), "persisted-id")
    XCTAssertTrue(keychain.savedValues.isEmpty)
  }

  func testGeneratesAndSavesIdentifierOnce() throws {
    let generated = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let keychain = MockKeychainStore()
    let store = ExportDeviceIdentifierStore(keychainStore: keychain, uuid: { generated })

    XCTAssertEqual(try store.identifier(), generated.uuidString)
    XCTAssertEqual(
      keychain.savedValues,
      [ExportDeviceIdentifierStore.account: generated.uuidString]
    )
    XCTAssertEqual(try store.identifier(), generated.uuidString)
    XCTAssertEqual(keychain.savedValues.count, 1)
  }

  func testSurfacesKeychainFailure() {
    let keychain = MockKeychainStore(error: .invalidStoredValue)
    let store = ExportDeviceIdentifierStore(keychainStore: keychain)

    XCTAssertThrowsError(try store.identifier()) { error in
      XCTAssertEqual(error as? KeychainStoreError, .invalidStoredValue)
    }
  }
}

private final class MockKeychainStore: KeychainStoring {
  var savedValues: [String: String] = [:]

  private let error: KeychainStoreError?
  private var storedValue: String?

  init(storedValue: String? = nil, error: KeychainStoreError? = nil) {
    self.storedValue = storedValue
    self.error = error
  }

  func read(account: String) throws -> String? {
    if let error {
      throw error
    }
    return storedValue
  }

  func save(_ value: String, account: String) throws {
    if let error {
      throw error
    }
    storedValue = value
    savedValues[account] = value
  }
}
