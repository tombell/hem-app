import XCTest

@testable import Hem

final class WeekRangeTests: XCTestCase {
  func testPreviousFullWeekUsesMondayBoundariesInLondon() throws {
    let now = try VitalsTestFixture.date("2026-06-24T12:00:00+01:00")
    let calendar = Calendar.vitalsDefault

    let range = WeekRange.previousFullWeek(now: now, calendar: calendar)

    XCTAssertEqual(
      ExportDateFormatting.dayString(for: range.start, calendar: calendar), "2026-06-15")
    XCTAssertEqual(ExportDateFormatting.dayString(for: range.end, calendar: calendar), "2026-06-22")
    XCTAssertEqual(range.kind, "previousFullWeek")
    XCTAssertEqual(range.timeZone, "Europe/London")
  }

  func testPreviousFullWeekOnMondayReturnsPriorWeek() throws {
    let now = try VitalsTestFixture.date("2026-06-22T09:00:00+01:00")
    let calendar = Calendar.vitalsDefault

    let range = WeekRange.previousFullWeek(now: now, calendar: calendar)

    XCTAssertEqual(
      ExportDateFormatting.dayString(for: range.start, calendar: calendar), "2026-06-15")
    XCTAssertEqual(ExportDateFormatting.dayString(for: range.end, calendar: calendar), "2026-06-22")
  }

  func testDaysIncludesSevenStartDates() throws {
    let now = try VitalsTestFixture.date("2026-06-24T12:00:00+01:00")

    let range = WeekRange.previousFullWeek(now: now, calendar: .vitalsDefault)

    XCTAssertEqual(range.days().count, 7)
  }

  func testCustomRangeUsesSelectedDaysWithExclusivePayloadEnd() throws {
    let start = try VitalsTestFixture.date("2026-06-10T18:30:00+01:00")
    let through = try VitalsTestFixture.date("2026-06-12T09:15:00+01:00")
    let calendar = Calendar.vitalsDefault

    let range = try WeekRange.custom(from: start, through: through, calendar: calendar)

    XCTAssertEqual(
      ExportDateFormatting.dayString(for: range.start, calendar: calendar), "2026-06-10")
    XCTAssertEqual(ExportDateFormatting.dayString(for: range.end, calendar: calendar), "2026-06-13")
    XCTAssertEqual(range.displayLabel, "10 Jun-12 Jun")
    XCTAssertEqual(range.days().count, 3)
    XCTAssertEqual(range.kind, "custom")
  }

  func testCustomRangeRejectsEndBeforeStart() throws {
    let start = try VitalsTestFixture.date("2026-06-12T09:15:00+01:00")
    let through = try VitalsTestFixture.date("2026-06-10T18:30:00+01:00")

    XCTAssertThrowsError(
      try WeekRange.custom(from: start, through: through, calendar: .vitalsDefault))
  }

  func testExportSummaryIntentDialogUsesInclusiveRange() throws {
    let range = try WeekRange.custom(
      from: VitalsTestFixture.date("2026-06-10T18:30:00+01:00"),
      through: VitalsTestFixture.date("2026-06-12T09:15:00+01:00")
    )
    let summary = ExportSummary(
      range: range,
      destinationHost: "hem-web.local",
      dailyMetricCount: 0,
      sampleCount: 0,
      workoutCount: 0,
      sleepSampleCount: 0
    )

    XCTAssertEqual(summary.intentDialog, "Exported Health data for 10 Jun-12 Jun.")
  }
}
