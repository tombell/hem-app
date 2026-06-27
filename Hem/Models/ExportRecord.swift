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
  let workoutCount: Int
  let sleepSampleCount: Int

  static let empty = ExportCounts(
    dayCount: 0,
    dailyMetricCount: 0,
    sampleCount: 0,
    workoutCount: 0,
    sleepSampleCount: 0
  )

  init(payload: ExportPayload, range: WeekRange) {
    dayCount = range.days().count
    dailyMetricCount = payload.dailyMetrics.count
    sampleCount = payload.samples.count
    workoutCount = payload.workouts.count
    sleepSampleCount = payload.sleep.count
  }

  init(
    dayCount: Int,
    dailyMetricCount: Int,
    sampleCount: Int,
    workoutCount: Int,
    sleepSampleCount: Int
  ) {
    self.dayCount = dayCount
    self.dailyMetricCount = dailyMetricCount
    self.sampleCount = sampleCount
    self.workoutCount = workoutCount
    self.sleepSampleCount = sleepSampleCount
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
