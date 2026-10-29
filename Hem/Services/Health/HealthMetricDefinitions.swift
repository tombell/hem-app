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
  private static let milligramUnit = HKUnit.gramUnit(with: .milli)
  private static let microgramUnit = HKUnit.gramUnit(with: .micro)
  private static let literPerMinuteUnit = HKUnit.liter().unitDivided(by: .minute())
  private static let microsiemensUnit = HKUnit.siemenUnit(with: .micro)
  private static let cadenceUnit = HKUnit.count().unitDivided(by: .minute())
  private static let decibelUnit = HKUnit.decibelAWeightedSoundPressureLevel()

  private static var physicalEffortUnit: HKUnit {
    HKUnit.kilocalorie().unitDivided(by: kilogramUnit.unitMultiplied(by: .hour()))
  }

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

  static let sampleQuantityMetrics: [SampleQuantityMetric] =
    [
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
      SampleQuantityMetric(
        identifier: .heartRateRecoveryOneMinute,
        type: "heartRateRecoveryOneMinute",
        unit: heartRateUnit,
        exportUnit: "count/min",
        exportCategory: .heart
      ),
      SampleQuantityMetric(
        identifier: .atrialFibrillationBurden,
        type: "atrialFibrillationBurden",
        unit: percentUnit,
        exportUnit: "%",
        exportCategory: .heart
      ),
      SampleQuantityMetric(
        identifier: .basalBodyTemperature,
        type: "basalBodyTemperature",
        unit: .degreeCelsius(),
        exportUnit: "degC",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .appleSleepingWristTemperature,
        type: "appleSleepingWristTemperature",
        unit: .degreeCelsius(),
        exportUnit: "degC",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .peripheralPerfusionIndex,
        type: "peripheralPerfusionIndex",
        unit: percentUnit,
        exportUnit: "%",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .forcedVitalCapacity,
        type: "forcedVitalCapacity",
        unit: literUnit,
        exportUnit: "L",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .forcedExpiratoryVolume1,
        type: "forcedExpiratoryVolume1",
        unit: literUnit,
        exportUnit: "L",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .peakExpiratoryFlowRate,
        type: "peakExpiratoryFlowRate",
        unit: literPerMinuteUnit,
        exportUnit: "L/min",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .electrodermalActivity,
        type: "electrodermalActivity",
        unit: microsiemensUnit,
        exportUnit: "uS",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .bloodAlcoholContent,
        type: "bloodAlcoholContent",
        unit: percentUnit,
        exportUnit: "%",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .insulinDelivery,
        type: "insulinDelivery",
        unit: .internationalUnit(),
        exportUnit: "IU",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .inhalerUsage,
        type: "inhalerUsage",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .vitals
      ),
      SampleQuantityMetric(
        identifier: .appleWalkingSteadiness,
        type: "appleWalkingSteadiness",
        unit: percentUnit,
        exportUnit: "%",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .numberOfTimesFallen,
        type: "numberOfTimesFallen",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .runningSpeed,
        type: "runningSpeed",
        unit: meterPerSecondUnit,
        exportUnit: "m/s",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .runningPower,
        type: "runningPower",
        unit: .watt(),
        exportUnit: "W",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .runningStrideLength,
        type: "runningStrideLength",
        unit: .meter(),
        exportUnit: "m",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .runningVerticalOscillation,
        type: "runningVerticalOscillation",
        unit: centimeterUnit,
        exportUnit: "cm",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .runningGroundContactTime,
        type: "runningGroundContactTime",
        unit: millisecondUnit,
        exportUnit: "ms",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .cyclingSpeed,
        type: "cyclingSpeed",
        unit: meterPerSecondUnit,
        exportUnit: "m/s",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .cyclingPower,
        type: "cyclingPower",
        unit: .watt(),
        exportUnit: "W",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .cyclingCadence,
        type: "cyclingCadence",
        unit: cadenceUnit,
        exportUnit: "count/min",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .cyclingFunctionalThresholdPower,
        type: "cyclingFunctionalThresholdPower",
        unit: .watt(),
        exportUnit: "W",
        exportCategory: .mobility
      ),
      SampleQuantityMetric(
        identifier: .appleStandTime,
        type: "appleStandTime",
        unit: .minute(),
        exportUnit: "min",
        exportCategory: .exercise
      ),
      SampleQuantityMetric(
        identifier: .appleMoveTime,
        type: "appleMoveTime",
        unit: .minute(),
        exportUnit: "min",
        exportCategory: .exercise
      ),
      SampleQuantityMetric(
        identifier: .physicalEffort,
        type: "physicalEffort",
        unit: physicalEffortUnit,
        exportUnit: "kcal/hr*kg",
        exportCategory: .exercise
      ),
      SampleQuantityMetric(
        identifier: .pushCount,
        type: "pushCount",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .exercise
      ),
      SampleQuantityMetric(
        identifier: .distanceWheelchair,
        type: "distanceWheelchair",
        unit: kilometerUnit,
        exportUnit: "km",
        exportCategory: .distance
      ),
      SampleQuantityMetric(
        identifier: .distanceDownhillSnowSports,
        type: "distanceDownhillSnowSports",
        unit: kilometerUnit,
        exportUnit: "km",
        exportCategory: .distance
      ),
      SampleQuantityMetric(
        identifier: .environmentalAudioExposure,
        type: "environmentalAudioExposure",
        unit: decibelUnit,
        exportUnit: "dBASPL",
        exportCategory: .hearing
      ),
      SampleQuantityMetric(
        identifier: .headphoneAudioExposure,
        type: "headphoneAudioExposure",
        unit: decibelUnit,
        exportUnit: "dBASPL",
        exportCategory: .hearing
      ),
      SampleQuantityMetric(
        identifier: .environmentalSoundReduction,
        type: "environmentalSoundReduction",
        unit: decibelUnit,
        exportUnit: "dBASPL",
        exportCategory: .hearing
      ),
      SampleQuantityMetric(
        identifier: .timeInDaylight,
        type: "timeInDaylight",
        unit: .minute(),
        exportUnit: "min",
        exportCategory: .environment
      ),
      SampleQuantityMetric(
        identifier: .uvExposure,
        type: "uvExposure",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .environment
      ),
      SampleQuantityMetric(
        identifier: .waterTemperature,
        type: "waterTemperature",
        unit: .degreeCelsius(),
        exportUnit: "degC",
        exportCategory: .environment
      ),
      SampleQuantityMetric(
        identifier: .underwaterDepth,
        type: "underwaterDepth",
        unit: .meter(),
        exportUnit: "m",
        exportCategory: .environment
      ),
      SampleQuantityMetric(
        identifier: .dietarySugar,
        type: "dietarySugar",
        unit: gramUnit,
        exportUnit: "g",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryFiber,
        type: "dietaryFiber",
        unit: gramUnit,
        exportUnit: "g",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryFatSaturated,
        type: "dietaryFatSaturated",
        unit: gramUnit,
        exportUnit: "g",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryFatMonounsaturated,
        type: "dietaryFatMonounsaturated",
        unit: gramUnit,
        exportUnit: "g",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryFatPolyunsaturated,
        type: "dietaryFatPolyunsaturated",
        unit: gramUnit,
        exportUnit: "g",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryCholesterol,
        type: "dietaryCholesterol",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietarySodium,
        type: "dietarySodium",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryPotassium,
        type: "dietaryPotassium",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryCalcium,
        type: "dietaryCalcium",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryIron,
        type: "dietaryIron",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryMagnesium,
        type: "dietaryMagnesium",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryZinc,
        type: "dietaryZinc",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryPhosphorus,
        type: "dietaryPhosphorus",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryChloride,
        type: "dietaryChloride",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryCopper,
        type: "dietaryCopper",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryManganese,
        type: "dietaryManganese",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminB6,
        type: "dietaryVitaminB6",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminC,
        type: "dietaryVitaminC",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminE,
        type: "dietaryVitaminE",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryNiacin,
        type: "dietaryNiacin",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryRiboflavin,
        type: "dietaryRiboflavin",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryThiamin,
        type: "dietaryThiamin",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryPantothenicAcid,
        type: "dietaryPantothenicAcid",
        unit: milligramUnit,
        exportUnit: "mg",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminA,
        type: "dietaryVitaminA",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminB12,
        type: "dietaryVitaminB12",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminD,
        type: "dietaryVitaminD",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryVitaminK,
        type: "dietaryVitaminK",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryFolate,
        type: "dietaryFolate",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryBiotin,
        type: "dietaryBiotin",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietarySelenium,
        type: "dietarySelenium",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryChromium,
        type: "dietaryChromium",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryMolybdenum,
        type: "dietaryMolybdenum",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .dietaryIodine,
        type: "dietaryIodine",
        unit: microgramUnit,
        exportUnit: "ug",
        exportCategory: .nutrition
      ),
      SampleQuantityMetric(
        identifier: .numberOfAlcoholicBeverages,
        type: "numberOfAlcoholicBeverages",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .nutrition
      ),
    ] + iOS18SampleQuantityMetrics

  static let categoryMetrics: [CategoryMetric] =
    [
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
      CategoryMetric(
        identifier: .highHeartRateEvent,
        type: "highHeartRateEvent",
        exportCategory: .heart,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .lowHeartRateEvent,
        type: "lowHeartRateEvent",
        exportCategory: .heart,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .irregularHeartRhythmEvent,
        type: "irregularHeartRhythmEvent",
        exportCategory: .heart,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .lowCardioFitnessEvent,
        type: "lowCardioFitnessEvent",
        exportCategory: .heart,
        valueName: lowCardioFitnessEventValueName
      ),
      CategoryMetric(
        identifier: .appleStandHour,
        type: "appleStandHour",
        exportCategory: .exercise,
        valueName: appleStandHourValueName
      ),
      CategoryMetric(
        identifier: .appleWalkingSteadinessEvent,
        type: "appleWalkingSteadinessEvent",
        exportCategory: .mobility,
        valueName: appleWalkingSteadinessEventValueName
      ),
      CategoryMetric(
        identifier: .environmentalAudioExposureEvent,
        type: "environmentalAudioExposureEvent",
        exportCategory: .hearing,
        valueName: environmentalAudioExposureEventValueName
      ),
      CategoryMetric(
        identifier: .headphoneAudioExposureEvent,
        type: "headphoneAudioExposureEvent",
        exportCategory: .hearing,
        valueName: headphoneAudioExposureEventValueName
      ),
      CategoryMetric(
        identifier: .menstrualFlow,
        type: "menstrualFlow",
        exportCategory: .cycleTracking,
        valueName: menstrualFlowValueName
      ),
      CategoryMetric(
        identifier: .intermenstrualBleeding,
        type: "intermenstrualBleeding",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .cervicalMucusQuality,
        type: "cervicalMucusQuality",
        exportCategory: .cycleTracking,
        valueName: cervicalMucusQualityValueName
      ),
      CategoryMetric(
        identifier: .ovulationTestResult,
        type: "ovulationTestResult",
        exportCategory: .cycleTracking,
        valueName: ovulationTestResultValueName
      ),
      CategoryMetric(
        identifier: .pregnancyTestResult,
        type: "pregnancyTestResult",
        exportCategory: .cycleTracking,
        valueName: pregnancyTestResultValueName
      ),
      CategoryMetric(
        identifier: .progesteroneTestResult,
        type: "progesteroneTestResult",
        exportCategory: .cycleTracking,
        valueName: progesteroneTestResultValueName
      ),
      CategoryMetric(
        identifier: .sexualActivity,
        type: "sexualActivity",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .contraceptive,
        type: "contraceptive",
        exportCategory: .cycleTracking,
        valueName: contraceptiveValueName
      ),
      CategoryMetric(
        identifier: .pregnancy,
        type: "pregnancy",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .lactation,
        type: "lactation",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .infrequentMenstrualCycles,
        type: "infrequentMenstrualCycles",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .irregularMenstrualCycles,
        type: "irregularMenstrualCycles",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .persistentIntermenstrualBleeding,
        type: "persistentIntermenstrualBleeding",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .prolongedMenstrualPeriods,
        type: "prolongedMenstrualPeriods",
        exportCategory: .cycleTracking,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .toothbrushingEvent,
        type: "toothbrushingEvent",
        exportCategory: .hygiene,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .handwashingEvent,
        type: "handwashingEvent",
        exportCategory: .hygiene,
        valueName: categoryRawValueName
      ),
    ] + iOS18CategoryMetrics

  private static var iOS18SampleQuantityMetrics: [SampleQuantityMetric] {
    guard #available(iOS 18.0, *) else {
      return []
    }

    return [
      SampleQuantityMetric(
        identifier: .appleSleepingBreathingDisturbances,
        type: "appleSleepingBreathingDisturbances",
        unit: .count(),
        exportUnit: "count",
        exportCategory: .sleep
      )
    ]
  }

  private static var iOS18CategoryMetrics: [CategoryMetric] {
    guard #available(iOS 18.0, *) else {
      return []
    }

    return [
      CategoryMetric(
        identifier: .sleepApneaEvent,
        type: "sleepApneaEvent",
        exportCategory: .sleep,
        valueName: categoryRawValueName
      ),
      CategoryMetric(
        identifier: .bleedingDuringPregnancy,
        type: "bleedingDuringPregnancy",
        exportCategory: .cycleTracking,
        valueName: menstrualFlowValueName
      ),
      CategoryMetric(
        identifier: .bleedingAfterPregnancy,
        type: "bleedingAfterPregnancy",
        exportCategory: .cycleTracking,
        valueName: menstrualFlowValueName
      ),
    ]
  }

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

  private static func lowCardioFitnessEventValueName(_ value: Int) -> String {
    switch HKCategoryValueLowCardioFitnessEvent(rawValue: value) {
    case .lowFitness:
      "lowFitness"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func appleStandHourValueName(_ value: Int) -> String {
    switch HKCategoryValueAppleStandHour(rawValue: value) {
    case .stood:
      "stood"
    case .idle:
      "idle"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func appleWalkingSteadinessEventValueName(_ value: Int) -> String {
    switch HKCategoryValueAppleWalkingSteadinessEvent(rawValue: value) {
    case .initialLow:
      "initialLow"
    case .initialVeryLow:
      "initialVeryLow"
    case .repeatLow:
      "repeatLow"
    case .repeatVeryLow:
      "repeatVeryLow"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func environmentalAudioExposureEventValueName(_ value: Int) -> String {
    switch HKCategoryValueEnvironmentalAudioExposureEvent(rawValue: value) {
    case .momentaryLimit:
      "momentaryLimit"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func headphoneAudioExposureEventValueName(_ value: Int) -> String {
    switch HKCategoryValueHeadphoneAudioExposureEvent(rawValue: value) {
    case .sevenDayLimit:
      "sevenDayLimit"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func menstrualFlowValueName(_ value: Int) -> String {
    switch HKCategoryValueMenstrualFlow(rawValue: value) {
    case .unspecified:
      "unspecified"
    case .light:
      "light"
    case .medium:
      "medium"
    case .heavy:
      "heavy"
    case .some(.none):
      "none"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func cervicalMucusQualityValueName(_ value: Int) -> String {
    switch HKCategoryValueCervicalMucusQuality(rawValue: value) {
    case .dry:
      "dry"
    case .sticky:
      "sticky"
    case .creamy:
      "creamy"
    case .watery:
      "watery"
    case .eggWhite:
      "eggWhite"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func ovulationTestResultValueName(_ value: Int) -> String {
    switch HKCategoryValueOvulationTestResult(rawValue: value) {
    case .negative:
      "negative"
    case .luteinizingHormoneSurge:
      "luteinizingHormoneSurge"
    case .indeterminate:
      "indeterminate"
    case .estrogenSurge:
      "estrogenSurge"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func pregnancyTestResultValueName(_ value: Int) -> String {
    switch HKCategoryValuePregnancyTestResult(rawValue: value) {
    case .negative:
      "negative"
    case .positive:
      "positive"
    case .indeterminate:
      "indeterminate"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func progesteroneTestResultValueName(_ value: Int) -> String {
    switch HKCategoryValueProgesteroneTestResult(rawValue: value) {
    case .negative:
      "negative"
    case .positive:
      "positive"
    case .indeterminate:
      "indeterminate"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }

  private static func contraceptiveValueName(_ value: Int) -> String {
    switch HKCategoryValueContraceptive(rawValue: value) {
    case .unspecified:
      "unspecified"
    case .implant:
      "implant"
    case .injection:
      "injection"
    case .intrauterineDevice:
      "intrauterineDevice"
    case .intravaginalRing:
      "intravaginalRing"
    case .oral:
      "oral"
    case .patch:
      "patch"
    case nil:
      "unknown-\(value)"
    @unknown default:
      "unknown-\(value)"
    }
  }
}
