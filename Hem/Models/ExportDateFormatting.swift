import Foundation

enum ExportDateFormatting {
  // Dates are parsed with ISO8601FormatStyle and formatted with one formatter per encoder:
  // creating an ISO8601DateFormatter per date dominated encoding and decoding time for
  // payloads with thousands of samples.
  static var jsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      guard let date = try? Date(string, strategy: .iso8601) else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Invalid ISO 8601 date: \(string)"
        )
      }
      return date
    }
    return decoder
  }

  static func jsonEncoder(timeZone: TimeZone) -> JSONEncoder {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = timeZone
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(formatter.string(from: date))
    }
    return encoder
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
    guard !calendar.isDate(start, inSameDayAs: end) else {
      return formatter.string(from: start)
    }
    return "\(formatter.string(from: start))-\(formatter.string(from: end))"
  }
}
