import Foundation
import HealthKit

struct HealthExportService {
  private let healthStore: HKHealthStore
  private let sourceProvider: ExportSourceProvider

  private var sampleSortDescriptor: NSSortDescriptor {
    NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
  }

  init(
    healthStore: HKHealthStore = HKHealthStore(),
    sourceProvider: ExportSourceProvider = ExportSourceProvider()
  ) {
    self.healthStore = healthStore
    self.sourceProvider = sourceProvider
  }

  static func identifier(for sample: HKSample) -> String {
    sample.uuid.uuidString
  }

  func makePayload(
    for range: WeekRange,
    including metrics: Set<ExportMetricCategory> = Set(ExportMetricCategory.allCases)
  ) async throws -> ExportPayload {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw HealthExportError.healthDataUnavailable
    }

    let dailyMetrics = try await dailyMetrics(for: range, including: metrics)
    let samples = try await sampleMetrics(for: range, including: metrics)
    let categorySamples = try await categorySamples(for: range, including: metrics)
    let workouts = metrics.contains(.workouts) ? try await workouts(for: range) : []
    let sleep = metrics.contains(.sleep) ? try await sleepSamples(for: range) : []
    let source = try await sourceProvider.current()

    return ExportPayload(
      source: source,
      generatedAt: Date(),
      range: ExportPayload.RangeMetadata(weekRange: range),
      dailyMetrics: dailyMetrics,
      samples: samples,
      categorySamples: categorySamples,
      workouts: workouts,
      sleep: sleep
    )
  }

  private func dailyMetrics(
    for range: WeekRange,
    including selectedMetrics: Set<ExportMetricCategory>
  ) async throws -> [ExportPayload.DailyMetric] {
    var valuesByKind:
      [HealthMetricDefinitions.DailyQuantityMetric.Kind: [Date: ExportPayload.QuantityValue]] = [:]
    for metric in HealthMetricDefinitions.dailyQuantityMetrics
    where selectedMetrics.contains(metric.exportCategory) {
      valuesByKind[metric.kind] = try await skippingUnavailableMetric(fallback: [:]) {
        try await dailyCumulativeValues(for: metric, range: range)
      }
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = range.resolvedTimeZone

    return range.days().compactMap { dayStart in
      let dailyMetric = ExportPayload.DailyMetric(
        date: ExportDateFormatting.dayString(for: dayStart, calendar: calendar),
        steps: valuesByKind[.steps]?[dayStart],
        activeEnergy: valuesByKind[.activeEnergy]?[dayStart],
        basalEnergy: valuesByKind[.basalEnergy]?[dayStart],
        exerciseTime: valuesByKind[.exerciseTime]?[dayStart],
        walkingRunningDistance: valuesByKind[.walkingRunningDistance]?[dayStart],
        cyclingDistance: valuesByKind[.cyclingDistance]?[dayStart],
        swimmingDistance: valuesByKind[.swimmingDistance]?[dayStart],
        swimmingStrokeCount: valuesByKind[.swimmingStrokeCount]?[dayStart],
        flightsClimbed: valuesByKind[.flightsClimbed]?[dayStart]
      )

      return dailyMetric.hasValues ? dailyMetric : nil
    }
  }

  private func dailyCumulativeValues(
    for metric: HealthMetricDefinitions.DailyQuantityMetric,
    range: WeekRange
  ) async throws -> [Date: ExportPayload.QuantityValue] {
    let quantityType = try HealthMetricDefinitions.quantityType(for: metric.identifier)
    let predicate = HKQuery.predicateForSamples(
      withStart: range.start,
      end: range.end,
      options: [.strictStartDate, .strictEndDate]
    )
    var interval = DateComponents()
    interval.day = 1

    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsCollectionQuery(
        quantityType: quantityType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum,
        anchorDate: range.start,
        intervalComponents: interval
      )

      query.initialResultsHandler = { _, collection, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let collection else {
          continuation.resume(returning: [:])
          return
        }

        var values: [Date: ExportPayload.QuantityValue] = [:]
        collection.enumerateStatistics(from: range.start, to: range.end) { statistics, _ in
          guard statistics.startDate < range.end,
            let quantity = statistics.sumQuantity()
          else {
            return
          }

          values[statistics.startDate] = ExportPayload.QuantityValue(
            value: quantity.doubleValue(for: metric.unit).roundedForExport(),
            unit: metric.exportUnit
          )
        }

        continuation.resume(returning: values)
      }

      healthStore.execute(query)
    }
  }

  private func sampleMetrics(
    for range: WeekRange,
    including selectedMetrics: Set<ExportMetricCategory>
  ) async throws -> [ExportPayload.HealthSample] {
    var samples: [ExportPayload.HealthSample] = []
    for metric in HealthMetricDefinitions.sampleQuantityMetrics
    where selectedMetrics.contains(metric.exportCategory) {
      let metricSamples: [ExportPayload.HealthSample] = try await skippingUnavailableMetric(
        fallback: []
      ) {
        try await quantitySamples(for: metric, range: range)
      }
      samples.append(contentsOf: metricSamples)
    }
    return samples.sorted { $0.start < $1.start }
  }

  private func quantitySamples(
    for metric: HealthMetricDefinitions.SampleQuantityMetric,
    range: WeekRange
  ) async throws
    -> [ExportPayload.HealthSample]
  {
    let quantityType = try HealthMetricDefinitions.quantityType(for: metric.identifier)
    let samples: [HKQuantitySample] = try await samples(of: quantityType, range: range)
    return samples.map { sample in
      ExportPayload.HealthSample(
        id: Self.identifier(for: sample),
        type: metric.type,
        start: sample.startDate,
        end: sample.endDate,
        value: sample.quantity.doubleValue(for: metric.unit).roundedForExport(),
        unit: metric.exportUnit
      )
    }
  }

  private func categorySamples(
    for range: WeekRange,
    including selectedMetrics: Set<ExportMetricCategory>
  ) async throws -> [ExportPayload.CategorySample] {
    var samples: [ExportPayload.CategorySample] = []
    for metric in HealthMetricDefinitions.categoryMetrics
    where selectedMetrics.contains(metric.exportCategory) {
      let metricSamples: [ExportPayload.CategorySample] = try await skippingUnavailableMetric(
        fallback: []
      ) {
        try await categorySamples(for: metric, range: range)
      }
      samples.append(contentsOf: metricSamples)
    }
    return samples.sorted { $0.start < $1.start }
  }

  private func categorySamples(
    for metric: HealthMetricDefinitions.CategoryMetric,
    range: WeekRange
  ) async throws -> [ExportPayload.CategorySample] {
    let categoryType = try HealthMetricDefinitions.categoryType(for: metric.identifier)
    let samples: [HKCategorySample] = try await samples(of: categoryType, range: range)
    return samples.map { sample in
      ExportPayload.CategorySample(
        id: Self.identifier(for: sample),
        type: metric.type,
        start: sample.startDate,
        end: sample.endDate,
        value: metric.valueName(sample.value)
      )
    }
  }

  private func samples<Sample: HKSample>(of sampleType: HKSampleType, range: WeekRange)
    async throws -> [Sample]
  {
    try await withCheckedThrowingContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: sampleType,
        predicate: samplePredicate(for: range),
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sampleSortDescriptor]
      ) { _, samples, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        continuation.resume(returning: (samples as? [Sample]) ?? [])
      }

      healthStore.execute(query)
    }
  }

  private func workouts(for range: WeekRange) async throws -> [ExportPayload.Workout] {
    let workouts: [HKWorkout] = try await samples(of: HKObjectType.workoutType(), range: range)
    return workouts.map { workout in
      ExportPayload.Workout(
        id: workout.uuid.uuidString,
        activityType: workout.workoutActivityType.exportName,
        start: workout.startDate,
        end: workout.endDate,
        duration: .init(value: (workout.duration / 60).roundedForExport(), unit: "min"),
        activeEnergy: workout.totalEnergyBurned.map {
          .init(value: $0.doubleValue(for: .kilocalorie()).roundedForExport(), unit: "kcal")
        },
        distance: workout.totalDistance.map {
          .init(
            value: $0.doubleValue(for: .meterUnit(with: .kilo)).roundedForExport(), unit: "km")
        }
      )
    }
  }

  private func sleepSamples(for range: WeekRange) async throws -> [ExportPayload.SleepSample] {
    let sleepType = try HealthMetricDefinitions.categoryType(for: .sleepAnalysis)
    let samples: [HKCategorySample] = try await samples(of: sleepType, range: range)
    return samples.map { sample in
      ExportPayload.SleepSample(
        id: Self.identifier(for: sample),
        start: sample.startDate,
        end: sample.endDate,
        value: HKCategoryValueSleepAnalysis(rawValue: sample.value)?.exportName
          ?? "unknown-\(sample.value)"
      )
    }
  }

  private func skippingUnavailableMetric<Value>(
    fallback: Value,
    _ operation: () async throws -> Value
  ) async throws -> Value {
    do {
      return try await operation()
    } catch HealthExportError.healthTypeUnavailable(_) {
      return fallback
    } catch let error as HKError where error.isAuthorizationOrAvailabilityFailure {
      return fallback
    } catch {
      throw error
    }
  }

  private func samplePredicate(for range: WeekRange) -> NSPredicate {
    HKQuery.predicateForSamples(
      withStart: range.start,
      end: range.end,
      options: [.strictStartDate, .strictEndDate]
    )
  }
}

extension HKError {
  fileprivate var isAuthorizationOrAvailabilityFailure: Bool {
    switch code {
    case .errorAuthorizationDenied, .errorAuthorizationNotDetermined, .errorHealthDataUnavailable:
      true
    default:
      false
    }
  }
}

enum HealthExportError: LocalizedError, Equatable {
  case healthDataUnavailable
  case healthAuthorizationFailed
  case healthTypeUnavailable(String)

  var errorDescription: String? {
    switch self {
    case .healthDataUnavailable:
      "Health data is not available on this device."
    case .healthAuthorizationFailed:
      "Health access was not granted."
    case .healthTypeUnavailable(let identifier):
      "The HealthKit type \(identifier) is not available on this device."
    }
  }
}

extension Double {
  fileprivate func roundedForExport() -> Double {
    (self * 1000).rounded() / 1000
  }
}

extension HKWorkoutActivityType {
  fileprivate var exportName: String {
    switch self {
    case .walking:
      "walking"
    case .running:
      "running"
    case .cycling:
      "cycling"
    case .swimming:
      "swimming"
    case .hiking:
      "hiking"
    case .traditionalStrengthTraining:
      "traditionalStrengthTraining"
    case .functionalStrengthTraining:
      "functionalStrengthTraining"
    case .yoga:
      "yoga"
    case .other:
      "other"
    default:
      "activity-\(rawValue)"
    }
  }
}

extension HKCategoryValueSleepAnalysis {
  fileprivate var exportName: String {
    switch self {
    case .inBed:
      "inBed"
    case .asleepUnspecified:
      "asleepUnspecified"
    case .asleepCore:
      "asleepCore"
    case .asleepDeep:
      "asleepDeep"
    case .asleepREM:
      "asleepREM"
    case .awake:
      "awake"
    @unknown default:
      "unknown-\(rawValue)"
    }
  }
}
