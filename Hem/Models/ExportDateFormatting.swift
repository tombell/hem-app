import Foundation

enum ExportDateFormatting {
  static func jsonEncoder(timeZone: TimeZone) -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(iso8601String(from: date, timeZone: timeZone))
    }
    return encoder
  }

  static func iso8601String(from date: Date, timeZone: TimeZone) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = timeZone
    return formatter.string(from: date)
  }

  static func dayString(for date: Date, calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_GB")
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  static func rangeLabel(for range: WeekRange) -> String {
    rangeLabel(start: range.start, end: range.end, timeZone: range.resolvedTimeZone)
  }

  static func rangeLabel(start: Date, end: Date, timeZone: TimeZone) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_GB")
    formatter.timeZone = timeZone
    formatter.setLocalizedDateFormatFromTemplate("MMM d")
    return "\(formatter.string(from: start))-\(formatter.string(from: end))"
  }
}
