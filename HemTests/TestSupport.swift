import XCTest

@testable import Hem

enum VitalsTestFixture {
  static func date(_ string: String, file: StaticString = #filePath, line: UInt = #line) throws
    -> Date
  {
    try XCTUnwrap(iso8601.date(from: string), file: file, line: line)
  }

  static func previousFullWeek(
    now string: String = "2026-06-24T12:00:00+01:00",
    calendar: Calendar = .vitalsDefault
  ) throws -> WeekRange {
    WeekRange.previousFullWeek(now: try date(string), calendar: calendar)
  }

  static var source: ExportPayload.Source {
    ExportPayload.Source(
      app: "Hem",
      bundleIdentifier: "dev.tombell.hem",
      deviceName: "Test iPhone",
      deviceSystemName: "iOS",
      deviceSystemVersion: "18.0"
    )
  }

  static func payload(now string: String = "2026-06-24T12:00:00+01:00") throws
    -> ExportPayload
  {
    let now = try date(string)
    let range = WeekRange.previousFullWeek(now: now, calendar: .vitalsDefault)

    return ExportPayload(
      source: source,
      generatedAt: now,
      range: ExportPayload.RangeMetadata(weekRange: range),
      dailyMetrics: [],
      samples: [],
      workouts: [],
      sleep: []
    )
  }

  private static var iso8601: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = .vitalsDefault
    formatter.locale = Locale(identifier: "en_GB")
    formatter.timeZone = TimeZone(identifier: "Europe/London")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    return formatter
  }
}
