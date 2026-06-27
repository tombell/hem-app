import HealthKit

enum HealthMetricDefinitions {
  struct DailyQuantityMetric {
    enum Kind: Hashable {
      case steps
      case activeEnergy
      case basalEnergy
      case exerciseTime
      case walkingRunningDistance
      case cyclingDistance
      case swimmingDistance
      case swimmingStrokeCount
      case flightsClimbed
    }

    let kind: Kind
    let identifier: HKQuantityTypeIdentifier
    let unit: HKUnit
    let exportUnit: String

    var exportCategory: ExportMetricCategory {
      switch kind {
      case .steps:
        .steps
      case .activeEnergy, .basalEnergy:
        .energy
      case .exerciseTime:
        .exercise
      case .walkingRunningDistance, .cyclingDistance, .swimmingDistance:
        .distance
      case .swimmingStrokeCount, .flightsClimbed:
        .exercise
      }
    }
  }

  struct SampleQuantityMetric {
    let identifier: HKQuantityTypeIdentifier
    let type: String
    let unit: HKUnit
    let exportUnit: String
    let exportCategory: ExportMetricCategory
  }

  struct CategoryMetric {
    let identifier: HKCategoryTypeIdentifier
    let type: String
    let exportCategory: ExportMetricCategory
    let valueName: (Int) -> String
  }

  private static let percentUnit = HKUnit.percent()
  private static let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
  private static let millisecondUnit = HKUnit.secondUnit(with: .milli)
  private static let kilometerUnit = HKUnit.meterUnit(with: .kilo)
  private static let kilogramUnit = HKUnit.gramUnit(with: .kilo)
  private static let millimeterOfMercuryUnit = HKUnit.millimeterOfMercury()
  private static let respiratoryRateUnit = HKUnit.count().unitDivided(by: .minute())
  private static let meterPerSecondUnit = HKUnit.meter().unitDivided(by: .second())
  private static let centimeterUnit = HKUnit.meterUnit(with: .centi)
  private static let gramUnit = HKUnit.gram()
  private static let literUnit = HKUnit.liter()
  private static let kilocalorieUnit = HKUnit.kilocalorie()

  private static var bloodGlucoseUnit: HKUnit {
    HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
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
      kind: .basalEnergy,
      identifier: .basalEnergyBurned,
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
    DailyQuantityMetric(
      kind: .cyclingDistance,
      identifier: .distanceCycling,
      unit: .meterUnit(with: .kilo),
      exportUnit: "km"
    ),
    DailyQuantityMetric(
      kind: .swimmingDistance,
      identifier: .distanceSwimming,
      unit: .meterUnit(with: .kilo),
      exportUnit: "km"
    ),
    DailyQuantityMetric(
      kind: .swimmingStrokeCount,
      identifier: .swimmingStrokeCount,
      unit: .count(),
      exportUnit: "count"
    ),
    DailyQuantityMetric(
      kind: .flightsClimbed,
      identifier: .flightsClimbed,
      unit: .count(),
      exportUnit: "count"
    ),
  ]

  static let sampleQuantityMetrics = [
    SampleQuantityMetric(
      identifier: .restingHeartRate,
      type: "restingHeartRate",
      unit: heartRateUnit,
      exportUnit: "count/min",
      exportCategory: .heart
    ),
    SampleQuantityMetric(
      identifier: .heartRate,
      type: "heartRate",
      unit: heartRateUnit,
      exportUnit: "count/min",
      exportCategory: .heart
    ),
    SampleQuantityMetric(
      identifier: .walkingHeartRateAverage,
      type: "walkingHeartRateAverage",
      unit: heartRateUnit,
      exportUnit: "count/min",
      exportCategory: .heart
    ),
    SampleQuantityMetric(
      identifier: .heartRateVariabilitySDNN,
      type: "heartRateVariabilitySDNN",
      unit: millisecondUnit,
      exportUnit: "ms",
      exportCategory: .heart
    ),
    SampleQuantityMetric(
      identifier: .vo2Max,
      type: "vo2Max",
      unit: HKUnit(from: "mL/kg*min"),
      exportUnit: "ml/kg*min",
      exportCategory: .heart
    ),
    SampleQuantityMetric(
      identifier: .bodyMass,
      type: "bodyMass",
      unit: kilogramUnit,
      exportUnit: "kg",
      exportCategory: .bodyMass
    ),
    SampleQuantityMetric(
      identifier: .height,
      type: "height",
      unit: .meter(),
      exportUnit: "m",
      exportCategory: .bodyComposition
    ),
    SampleQuantityMetric(
      identifier: .bodyMassIndex,
      type: "bodyMassIndex",
      unit: .count(),
      exportUnit: "count",
      exportCategory: .bodyComposition
    ),
    SampleQuantityMetric(
      identifier: .bodyFatPercentage,
      type: "bodyFatPercentage",
      unit: percentUnit,
      exportUnit: "%",
      exportCategory: .bodyComposition
    ),
    SampleQuantityMetric(
      identifier: .leanBodyMass,
      type: "leanBodyMass",
      unit: kilogramUnit,
      exportUnit: "kg",
      exportCategory: .bodyComposition
    ),
    SampleQuantityMetric(
      identifier: .waistCircumference,
      type: "waistCircumference",
      unit: centimeterUnit,
      exportUnit: "cm",
      exportCategory: .bodyComposition
    ),
    SampleQuantityMetric(
      identifier: .respiratoryRate,
      type: "respiratoryRate",
      unit: respiratoryRateUnit,
      exportUnit: "count/min",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .oxygenSaturation,
      type: "oxygenSaturation",
      unit: percentUnit,
      exportUnit: "%",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .bodyTemperature,
      type: "bodyTemperature",
      unit: .degreeCelsius(),
      exportUnit: "degC",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .bloodPressureSystolic,
      type: "bloodPressureSystolic",
      unit: millimeterOfMercuryUnit,
      exportUnit: "mmHg",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .bloodPressureDiastolic,
      type: "bloodPressureDiastolic",
      unit: millimeterOfMercuryUnit,
      exportUnit: "mmHg",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .bloodGlucose,
      type: "bloodGlucose",
      unit: bloodGlucoseUnit,
      exportUnit: "mg/dL",
      exportCategory: .vitals
    ),
    SampleQuantityMetric(
      identifier: .walkingSpeed,
      type: "walkingSpeed",
      unit: meterPerSecondUnit,
      exportUnit: "m/s",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .walkingStepLength,
      type: "walkingStepLength",
      unit: centimeterUnit,
      exportUnit: "cm",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .walkingAsymmetryPercentage,
      type: "walkingAsymmetryPercentage",
      unit: percentUnit,
      exportUnit: "%",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .walkingDoubleSupportPercentage,
      type: "walkingDoubleSupportPercentage",
      unit: percentUnit,
      exportUnit: "%",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .sixMinuteWalkTestDistance,
      type: "sixMinuteWalkTestDistance",
      unit: .meter(),
      exportUnit: "m",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .stairAscentSpeed,
      type: "stairAscentSpeed",
      unit: meterPerSecondUnit,
      exportUnit: "m/s",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .stairDescentSpeed,
      type: "stairDescentSpeed",
      unit: meterPerSecondUnit,
      exportUnit: "m/s",
      exportCategory: .mobility
    ),
    SampleQuantityMetric(
      identifier: .dietaryEnergyConsumed,
      type: "dietaryEnergyConsumed",
      unit: kilocalorieUnit,
      exportUnit: "kcal",
      exportCategory: .nutrition
    ),
    SampleQuantityMetric(
      identifier: .dietaryWater,
      type: "dietaryWater",
      unit: literUnit,
      exportUnit: "L",
      exportCategory: .nutrition
    ),
    SampleQuantityMetric(
      identifier: .dietaryCaffeine,
      type: "dietaryCaffeine",
      unit: gramUnit,
      exportUnit: "g",
      exportCategory: .nutrition
    ),
    SampleQuantityMetric(
      identifier: .dietaryProtein,
      type: "dietaryProtein",
      unit: gramUnit,
      exportUnit: "g",
      exportCategory: .nutrition
    ),
    SampleQuantityMetric(
      identifier: .dietaryCarbohydrates,
      type: "dietaryCarbohydrates",
      unit: gramUnit,
      exportUnit: "g",
      exportCategory: .nutrition
    ),
    SampleQuantityMetric(
      identifier: .dietaryFatTotal,
      type: "dietaryFatTotal",
      unit: gramUnit,
      exportUnit: "g",
      exportCategory: .nutrition
    ),
  ]

  static let categoryMetrics = [
    CategoryMetric(
      identifier: .mindfulSession,
      type: "mindfulSession",
      exportCategory: .mindfulness,
      valueName: categoryRawValueName
    ),
    CategoryMetric(
      identifier: .abdominalCramps,
      type: "abdominalCramps",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .acne,
      type: "acne",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .appetiteChanges,
      type: "appetiteChanges",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .bladderIncontinence,
      type: "bladderIncontinence",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .bloating,
      type: "bloating",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .breastPain,
      type: "breastPain",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .chestTightnessOrPain,
      type: "chestTightnessOrPain",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .chills,
      type: "chills",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .constipation,
      type: "constipation",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .coughing,
      type: "coughing",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .diarrhea,
      type: "diarrhea",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .dizziness,
      type: "dizziness",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .fainting,
      type: "fainting",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .fatigue,
      type: "fatigue",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .fever,
      type: "fever",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .generalizedBodyAche,
      type: "generalizedBodyAche",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .headache,
      type: "headache",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .heartburn,
      type: "heartburn",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .hotFlashes,
      type: "hotFlashes",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .lossOfSmell,
      type: "lossOfSmell",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .lossOfTaste,
      type: "lossOfTaste",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .lowerBackPain,
      type: "lowerBackPain",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .memoryLapse,
      type: "memoryLapse",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .moodChanges,
      type: "moodChanges",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .nausea,
      type: "nausea",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .pelvicPain,
      type: "pelvicPain",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .rapidPoundingOrFlutteringHeartbeat,
      type: "rapidPoundingOrFlutteringHeartbeat",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .runnyNose,
      type: "runnyNose",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .shortnessOfBreath,
      type: "shortnessOfBreath",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .sinusCongestion,
      type: "sinusCongestion",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .skippedHeartbeat,
      type: "skippedHeartbeat",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .sleepChanges,
      type: "sleepChanges",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .soreThroat,
      type: "soreThroat",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .vaginalDryness,
      type: "vaginalDryness",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .vomiting,
      type: "vomiting",
      exportCategory: .symptoms,
      valueName: severityValueName
    ),
    CategoryMetric(
      identifier: .wheezing,
      type: "wheezing",
      exportCategory: .symptoms,
      valueName: severityValueName
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

    let categoryTypes =
      categoryMetrics
      .compactMap { HKObjectType.categoryType(forIdentifier: $0.identifier) }
    for categoryType in categoryTypes {
      types.insert(categoryType)
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

  private static func categoryRawValueName(_ value: Int) -> String {
    "value-\(value)"
  }

  private static func severityValueName(_ value: Int) -> String {
    switch HKCategoryValueSeverity(rawValue: value) {
    case .unspecified:
      "unspecified"
    case .notPresent:
      "notPresent"
    case .mild:
      "mild"
    case .moderate:
      "moderate"
    case .severe:
      "severe"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }
}
