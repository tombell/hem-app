import Foundation

struct ExportRecord: Codable, Identifiable, Equatable {
  let id: UUID
  let range: WeekRange
  let mode: ExportMode
  let metrics: [ExportMetricCategory]
  var status: ExportStatus
  var destinationHost: String
  var endpointURLString: String
  let requestedAt: Date
  var startedAt: Date?
  var completedAt: Date?
  var attemptCount: Int
  var counts: ExportCounts
  var retrySourceID: UUID?
  var payloadFileName: String?
  var errorMessage: String?
  var errorCode: String?
  var httpStatus: Int?
  var serverResponseSummary: String?
  var serverImportID: Int? = nil
  var serverImportStatus: HemWebImportStatus? = nil
  var serverCounts: HemWebImportCounts? = nil
  var nextRetryAt: Date? = nil
}

enum ExportStatus: String, Codable, Equatable {
  case sending
  case succeeded
  case failed
  case queued
}

enum ExportMode: String, Codable, Equatable {
  case manual
  case retry
  case incremental
  case shortcut
}

struct ExportCounts: Codable, Equatable {
  let dayCount: Int
  let dailyMetricCount: Int
  let sampleCount: Int
  let categorySampleCount: Int
  let workoutCount: Int
  let sleepSampleCount: Int

  static let empty = ExportCounts(
    dayCount: 0,
    dailyMetricCount: 0,
    sampleCount: 0,
    categorySampleCount: 0,
    workoutCount: 0,
    sleepSampleCount: 0
  )

  init(payload: ExportPayload, range: WeekRange) {
    dayCount = range.days().count
    dailyMetricCount = payload.dailyMetrics.count
    sampleCount = payload.samples.count
    categorySampleCount = payload.categorySamples.count
    workoutCount = payload.workouts.count
    sleepSampleCount = payload.sleep.count
  }

  init(
    dayCount: Int,
    dailyMetricCount: Int,
    sampleCount: Int,
    categorySampleCount: Int = 0,
    workoutCount: Int,
    sleepSampleCount: Int
  ) {
    self.dayCount = dayCount
    self.dailyMetricCount = dailyMetricCount
    self.sampleCount = sampleCount
    self.categorySampleCount = categorySampleCount
    self.workoutCount = workoutCount
    self.sleepSampleCount = sleepSampleCount
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    dayCount = try container.decode(Int.self, forKey: .dayCount)
    dailyMetricCount = try container.decode(Int.self, forKey: .dailyMetricCount)
    sampleCount = try container.decode(Int.self, forKey: .sampleCount)
    categorySampleCount = try container.decodeIfPresent(Int.self, forKey: .categorySampleCount) ?? 0
    workoutCount = try container.decode(Int.self, forKey: .workoutCount)
    sleepSampleCount = try container.decode(Int.self, forKey: .sleepSampleCount)
  }
}

struct ExportDraft: Identifiable, Equatable {
  var id: String {
    "\(mode.rawValue)-\(range.start.timeIntervalSince1970)-\(range.end.timeIntervalSince1970)-\(metrics.map(\.rawValue).joined(separator: ","))"
  }

  let range: WeekRange
  let mode: ExportMode
  let metrics: [ExportMetricCategory]
  let destinationHost: String
  let endpointURLString: String
  let payload: ExportPayload
  let counts: ExportCounts
  let warnings: [String]
}

struct ExportDiagnosticsBundle: Equatable {
  let text: String
}
