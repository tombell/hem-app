import Foundation

struct WeekRange: Codable, Equatable, Sendable {
  static func previousDay(now: Date = Date(), calendar: Calendar = .vitalsDefault) -> WeekRange {
    var calendar = calendar
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4

    let currentDayStart = calendar.startOfDay(for: now)
    let previousDayStart =
      calendar.date(byAdding: .day, value: -1, to: currentDayStart) ?? currentDayStart

    return WeekRange(
      start: previousDayStart, end: currentDayStart, calendar: calendar, kind: "previousDay")
  }

  static func previousFullWeek(now: Date = Date(), calendar: Calendar = .vitalsDefault) -> WeekRange
  {
    var calendar = calendar
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4

    let currentWeekStart =
      calendar.dateInterval(of: .weekOfYear, for: now)?.start
      ?? calendar.startOfDay(for: now)
    let previousWeekStart =
      calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)
      ?? calendar.date(byAdding: .day, value: -7, to: currentWeekStart)
      ?? currentWeekStart

    return WeekRange(start: previousWeekStart, end: currentWeekStart, calendar: calendar)
  }

  static func custom(
    from startDate: Date, through throughDate: Date, calendar: Calendar = .vitalsDefault
  ) throws -> WeekRange {
    var calendar = calendar
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4

    let start = calendar.startOfDay(for: startDate)
    let through = calendar.startOfDay(for: throughDate)
    guard let end = calendar.date(byAdding: .day, value: 1, to: through),
      start < end
    else {
      throw WeekRangeError.invalidDateRange
    }

    return WeekRange(start: start, end: end, calendar: calendar, kind: "custom")
  }

  let start: Date
  let end: Date
  let calendar: String
  let timeZone: String
  let kind: String

  var resolvedTimeZone: TimeZone {
    TimeZone(identifier: timeZone) ?? .current
  }

  var displayLabel: String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = resolvedTimeZone

    let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: end) ?? end
    return ExportDateFormatting.rangeLabel(
      start: start, end: inclusiveEnd, timeZone: resolvedTimeZone)
  }

  init(start: Date, end: Date, calendar: Calendar, kind: String = "previousFullWeek") {
    self.start = start
    self.end = end
    self.calendar = "gregorian"
    timeZone = calendar.timeZone.identifier
    self.kind = kind
  }

  func days() -> [Date] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = resolvedTimeZone

    var dates: [Date] = []
    var current = start

    while current < end {
      dates.append(current)
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
        break
      }
      current = next
    }

    return dates
  }
}

enum WeekRangeError: LocalizedError, Equatable {
  case invalidDateRange

  var errorDescription: String? {
    "Choose an end date after the start date."
  }
}

extension Calendar {
  static var vitalsDefault: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_GB")
    calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
  }
}
