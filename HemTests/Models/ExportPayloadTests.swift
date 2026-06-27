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
}
