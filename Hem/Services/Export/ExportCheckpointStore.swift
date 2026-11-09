import Foundation

struct ExportCheckpointStore {
  private let lastSuccessEndKey = "dev.tombell.hem.lastSuccessfulExportEnd"
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func loadLastSuccessEnd() -> Date? {
    userDefaults.object(forKey: lastSuccessEndKey) as? Date
  }

  /// Records a successful export end, never moving the checkpoint backwards so that
  /// backfilling an older range does not cause later data to be re-exported.
  func advanceLastSuccessEnd(to date: Date) {
    if let current = loadLastSuccessEnd(), current >= date {
      return
    }
    userDefaults.set(date, forKey: lastSuccessEndKey)
  }

  func reset() {
    userDefaults.removeObject(forKey: lastSuccessEndKey)
  }
}
