import Foundation

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
