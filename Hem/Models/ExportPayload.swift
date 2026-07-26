import Foundation

struct ExportPayload: Codable, Equatable {
  let schemaVersion: Int
  let source: Source
  let generatedAt: Date
  let range: RangeMetadata
  let dailyMetrics: [DailyMetric]
  let samples: [HealthSample]
  let categorySamples: [CategorySample]
  let workouts: [Workout]
  let sleep: [SleepSample]

  init(
    schemaVersion: Int = 1,
    source: Source,
    generatedAt: Date,
    range: RangeMetadata,
    dailyMetrics: [DailyMetric],
    samples: [HealthSample],
    categorySamples: [CategorySample] = [],
    workouts: [Workout],
    sleep: [SleepSample]
  ) {
    self.schemaVersion = schemaVersion
    self.source = source
    self.generatedAt = generatedAt
    self.range = range
    self.dailyMetrics = dailyMetrics
    self.samples = samples
    self.categorySamples = categorySamples
    self.workouts = workouts
    self.sleep = sleep
  }
}

extension ExportPayload {
  struct Source: Codable, Equatable {
    let app: String
    let bundleIdentifier: String
    let deviceIdentifier: String?
    let deviceName: String
    let deviceSystemName: String
    let deviceSystemVersion: String

    init(
      app: String,
      bundleIdentifier: String,
      deviceIdentifier: String? = nil,
      deviceName: String,
      deviceSystemName: String,
      deviceSystemVersion: String
    ) {
      self.app = app
      self.bundleIdentifier = bundleIdentifier
      self.deviceIdentifier = deviceIdentifier
      self.deviceName = deviceName
      self.deviceSystemName = deviceSystemName
      self.deviceSystemVersion = deviceSystemVersion
    }
  }

  struct RangeMetadata: Codable, Equatable {
    let start: Date
    let end: Date
    let calendar: String
    let timeZone: String
    let kind: String

    init(weekRange: WeekRange) {
      start = weekRange.start
      end = weekRange.end
      calendar = weekRange.calendar
      timeZone = weekRange.timeZone
      kind = weekRange.kind
    }
  }

  struct QuantityValue: Codable, Equatable {
    let value: Double
    let unit: String
  }

  struct DailyMetric: Codable, Equatable {
    let date: String
    let steps: QuantityValue?
    let activeEnergy: QuantityValue?
    let basalEnergy: QuantityValue?
    let exerciseTime: QuantityValue?
    let walkingRunningDistance: QuantityValue?
    let cyclingDistance: QuantityValue?
    let swimmingDistance: QuantityValue?
    let swimmingStrokeCount: QuantityValue?
    let flightsClimbed: QuantityValue?

    var hasValues: Bool {
      steps != nil || activeEnergy != nil || basalEnergy != nil || exerciseTime != nil
        || walkingRunningDistance != nil || cyclingDistance != nil || swimmingDistance != nil
        || swimmingStrokeCount != nil || flightsClimbed != nil
    }
  }

  struct HealthSample: Codable, Equatable {
    let id: String?
    let type: String
    let start: Date
    let end: Date
    let value: Double
    let unit: String

    init(
      id: String? = nil,
      type: String,
      start: Date,
      end: Date,
      value: Double,
      unit: String
    ) {
      self.id = id
      self.type = type
      self.start = start
      self.end = end
      self.value = value
      self.unit = unit
    }
  }

  struct CategorySample: Codable, Equatable {
    let id: String?
    let type: String
    let start: Date
    let end: Date
    let value: String

    init(id: String? = nil, type: String, start: Date, end: Date, value: String) {
      self.id = id
      self.type = type
      self.start = start
      self.end = end
      self.value = value
    }
  }

  struct Workout: Codable, Equatable {
    let id: String
    let activityType: String
    let start: Date
    let end: Date
    let duration: QuantityValue
    let activeEnergy: QuantityValue?
    let distance: QuantityValue?
  }

  struct SleepSample: Codable, Equatable {
    let id: String?
    let start: Date
    let end: Date
    let value: String

    init(id: String? = nil, start: Date, end: Date, value: String) {
      self.id = id
      self.start = start
      self.end = end
      self.value = value
    }
  }
}

enum ExportPayloadEncoding {
  static func encode(_ payload: ExportPayload) throws -> Data {
    let timeZone = TimeZone(identifier: payload.range.timeZone) ?? .current
    return try ExportDateFormatting.jsonEncoder(timeZone: timeZone).encode(payload)
  }
}
