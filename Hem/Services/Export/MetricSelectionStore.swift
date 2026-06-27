import Foundation

struct ExportDateRangeStore {
  private let selectedStartDateKey = "dev.tombell.hem.selectedExportStartDate"
  private let selectedThroughDateKey = "dev.tombell.hem.selectedExportThroughDate"
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func load(defaultRange: WeekRange) -> (startDate: Date, throughDate: Date) {
    let defaultThroughDate = throughDate(for: defaultRange)
    guard let startDate = userDefaults.object(forKey: selectedStartDateKey) as? Date,
      let throughDate = userDefaults.object(forKey: selectedThroughDateKey) as? Date
    else {
      return (defaultRange.start, defaultThroughDate)
    }

    let calendar = Calendar.vitalsDefault
    guard calendar.startOfDay(for: throughDate) >= calendar.startOfDay(for: startDate) else {
      return (defaultRange.start, defaultThroughDate)
    }

    return (startDate, throughDate)
  }

  func save(startDate: Date, throughDate: Date) {
    userDefaults.set(startDate, forKey: selectedStartDateKey)
    userDefaults.set(throughDate, forKey: selectedThroughDateKey)
  }

  func reset() {
    userDefaults.removeObject(forKey: selectedStartDateKey)
    userDefaults.removeObject(forKey: selectedThroughDateKey)
  }

  private func throughDate(for range: WeekRange) -> Date {
    Calendar.vitalsDefault.date(byAdding: .day, value: -1, to: range.end) ?? range.start
  }
}

struct MetricSelectionStore {
  private let selectedMetricsKey = "dev.tombell.hem.selectedExportMetrics"
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func load() -> Set<ExportMetricCategory> {
    guard let rawValues = userDefaults.array(forKey: selectedMetricsKey) as? [String] else {
      return Set(ExportMetricCategory.allCases)
    }

    let metrics = rawValues.compactMap(ExportMetricCategory.init(rawValue:))
    return metrics.isEmpty ? Set(ExportMetricCategory.allCases) : Set(metrics)
  }

  func save(_ metrics: Set<ExportMetricCategory>) {
    let rawValues = ExportMetricCategory.allCases
      .filter(metrics.contains)
      .map(\.rawValue)
    userDefaults.set(rawValues, forKey: selectedMetricsKey)
  }

  func reset() {
    userDefaults.removeObject(forKey: selectedMetricsKey)
  }
}
