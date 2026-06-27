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

  func saveLastSuccessEnd(_ date: Date) {
    userDefaults.set(date, forKey: lastSuccessEndKey)
  }

  func reset() {
    userDefaults.removeObject(forKey: lastSuccessEndKey)
  }
}
