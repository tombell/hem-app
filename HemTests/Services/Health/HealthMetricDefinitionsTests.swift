import HealthKit
import XCTest

@testable import Hem

final class HealthMetricDefinitionsTests: XCTestCase {
  func testReadTypesCoverExportMetricDefinitions() {
    let readTypeIdentifiers = Set(HealthMetricDefinitions.readTypes.map(\.identifier))
    let dailyIdentifiers = HealthMetricDefinitions.dailyQuantityMetrics.map(\.identifier.rawValue)
    let sampleIdentifiers = HealthMetricDefinitions.sampleQuantityMetrics.map(\.identifier.rawValue)

    XCTAssertTrue(Set(dailyIdentifiers).isSubset(of: readTypeIdentifiers))
    XCTAssertTrue(Set(sampleIdentifiers).isSubset(of: readTypeIdentifiers))
    XCTAssertTrue(readTypeIdentifiers.contains(HKCategoryTypeIdentifier.sleepAnalysis.rawValue))
    XCTAssertTrue(readTypeIdentifiers.contains(HKObjectType.workoutType().identifier))
  }
}
