import Foundation
import HealthKit

final class HealthAuthorizationService {
  enum Status: Equatable {
    case unknown
    case unavailable
    case notRequested
    case requested

    var displayName: String {
      switch self {
      case .unknown:
        "Unknown"
      case .unavailable:
        "Unavailable"
      case .notRequested:
        "Not requested"
      case .requested:
        "Requested"
      }
    }

    var detail: String {
      switch self {
      case .unknown:
        "HealthKit status has not been checked yet."
      case .unavailable:
        "Health data is not available on this device."
      case .notRequested:
        "Hem needs read access to the selected Health categories before export."
      case .requested:
        "iOS does not reveal read access state. Denied categories export as unavailable."
      }
    }
  }

  private let healthStore: HKHealthStore
  private let userDefaults: UserDefaults
  private let didRequestKey = "dev.tombell.hem.healthAuthorizationRequested"

  init(healthStore: HKHealthStore = HKHealthStore(), userDefaults: UserDefaults = .standard) {
    self.healthStore = healthStore
    self.userDefaults = userDefaults
  }

  func status() -> Status {
    guard HKHealthStore.isHealthDataAvailable() else {
      return .unavailable
    }

    return userDefaults.bool(forKey: didRequestKey) ? .requested : .notRequested
  }

  func requestAuthorization() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw HealthExportError.healthDataUnavailable
    }

    let healthStore = healthStore
    let success = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Bool, Error>) in
      healthStore.requestAuthorization(toShare: [], read: HealthMetricDefinitions.readTypes) {
        success, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        continuation.resume(returning: success)
      }
    }

    guard success else {
      throw HealthExportError.healthAuthorizationFailed
    }

    userDefaults.set(true, forKey: didRequestKey)
  }
}
