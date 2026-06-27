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
        "Request Health access again when new export categories are added. Simulator may show Health read access as not determined until the request completes."
      case .requested:
        "Health read access was requested for the current export categories. iOS may still show read authorization as not determined because it does not reveal read access state."
      }
    }
  }

  private let healthStore: HKHealthStore
  private let userDefaults: UserDefaults
  private let didRequestKey = "dev.tombell.hem.healthAuthorizationRequested"
  private let requestedReadTypesKey = "dev.tombell.hem.healthAuthorizationRequestedReadTypes"

  init(healthStore: HKHealthStore = HKHealthStore(), userDefaults: UserDefaults = .standard) {
    self.healthStore = healthStore
    self.userDefaults = userDefaults
  }

  func status() -> Status {
    guard HKHealthStore.isHealthDataAvailable() else {
      return .unavailable
    }

    let requestedReadTypes = userDefaults.string(forKey: requestedReadTypesKey)
    let currentReadTypes = Self.readTypesFingerprint
    return userDefaults.bool(forKey: didRequestKey) && requestedReadTypes == currentReadTypes
      ? .requested : .notRequested
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
    userDefaults.set(Self.readTypesFingerprint, forKey: requestedReadTypesKey)
  }

  static var readTypesFingerprint: String {
    HealthMetricDefinitions.readTypes
      .map(\.identifier)
      .sorted()
      .joined(separator: "\n")
  }
}
