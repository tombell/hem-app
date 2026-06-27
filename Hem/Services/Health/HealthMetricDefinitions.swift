import HealthKit

enum HealthMetricDefinitions {
  struct DailyQuantityMetric {
    enum Kind: Hashable {
      case steps
      case activeEnergy
      case exerciseTime
      case walkingRunningDistance
    }

    let kind: Kind
    let identifier: HKQuantityTypeIdentifier
    let unit: HKUnit
    let exportUnit: String

    var exportCategory: ExportMetricCategory {
      switch kind {
      case .steps:
        .steps
      case .activeEnergy:
        .energy
      case .exerciseTime:
        .exercise
      case .walkingRunningDistance:
        .distance
      }
    }
  }

  struct SampleQuantityMetric {
    let identifier: HKQuantityTypeIdentifier
    let type: String
    let unit: HKUnit
    let exportUnit: String

    var exportCategory: ExportMetricCategory {
      switch identifier {
      case .bodyMass:
        .bodyMass
      default:
        .heart
      }
    }
  }

  static let dailyQuantityMetrics = [
    DailyQuantityMetric(
      kind: .steps,
      identifier: .stepCount,
      unit: .count(),
      exportUnit: "count"
    ),
    DailyQuantityMetric(
      kind: .activeEnergy,
      identifier: .activeEnergyBurned,
      unit: .kilocalorie(),
      exportUnit: "kcal"
    ),
    DailyQuantityMetric(
      kind: .exerciseTime,
      identifier: .appleExerciseTime,
      unit: .minute(),
      exportUnit: "min"
    ),
    DailyQuantityMetric(
      kind: .walkingRunningDistance,
      identifier: .distanceWalkingRunning,
      unit: .meterUnit(with: .kilo),
      exportUnit: "km"
    ),
  ]

  static let sampleQuantityMetrics = [
    SampleQuantityMetric(
      identifier: .restingHeartRate,
      type: "restingHeartRate",
      unit: .count().unitDivided(by: .minute()),
      exportUnit: "count/min"
    ),
    SampleQuantityMetric(
      identifier: .heartRateVariabilitySDNN,
      type: "heartRateVariabilitySDNN",
      unit: .secondUnit(with: .milli),
      exportUnit: "ms"
    ),
    SampleQuantityMetric(
      identifier: .vo2Max,
      type: "vo2Max",
      unit: HKUnit(from: "mL/kg*min"),
      exportUnit: "ml/kg*min"
    ),
    SampleQuantityMetric(
      identifier: .bodyMass,
      type: "bodyMass",
      unit: .gramUnit(with: .kilo),
      exportUnit: "kg"
    ),
  ]

  static var readTypes: Set<HKObjectType> {
    var types = Set<HKObjectType>()

    let quantityTypes =
      (dailyQuantityMetrics.map(\.identifier) + sampleQuantityMetrics.map(\.identifier))
      .compactMap(HKObjectType.quantityType(forIdentifier:))

    for quantityType in quantityTypes {
      types.insert(quantityType)
    }

    if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
      types.insert(sleepType)
    }

    types.insert(HKObjectType.workoutType())
    return types
  }

  static func quantityType(for identifier: HKQuantityTypeIdentifier) throws -> HKQuantityType {
    guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
      throw HealthExportError.healthTypeUnavailable(identifier.rawValue)
    }

    return type
  }

  static func categoryType(for identifier: HKCategoryTypeIdentifier) throws -> HKCategoryType {
    guard let type = HKObjectType.categoryType(forIdentifier: identifier) else {
      throw HealthExportError.healthTypeUnavailable(identifier.rawValue)
    }

    return type
  }
}
