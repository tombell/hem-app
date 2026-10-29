import HealthKit
import XCTest

@testable import Hem

final class HealthMetricDefinitionsTests: XCTestCase {
  func testReadTypesCoverExportMetricDefinitions() {
    let readTypeIdentifiers = Set(HealthMetricDefinitions.readTypes.map(\.identifier))
    let dailyIdentifiers = HealthMetricDefinitions.dailyQuantityMetrics.map(\.identifier.rawValue)
    let sampleIdentifiers = HealthMetricDefinitions.sampleQuantityMetrics.map(\.identifier.rawValue)
    let categoryIdentifiers = HealthMetricDefinitions.categoryMetrics.map(\.identifier.rawValue)

    XCTAssertTrue(Set(dailyIdentifiers).isSubset(of: readTypeIdentifiers))
    XCTAssertTrue(Set(sampleIdentifiers).isSubset(of: readTypeIdentifiers))
    XCTAssertTrue(Set(categoryIdentifiers).isSubset(of: readTypeIdentifiers))
    XCTAssertTrue(readTypeIdentifiers.contains(HKCategoryTypeIdentifier.sleepAnalysis.rawValue))
    XCTAssertTrue(readTypeIdentifiers.contains(HKObjectType.workoutType().identifier))
  }

  func testExportMetricDefinitionsAreUnique() {
    let identifiers =
      HealthMetricDefinitions.dailyQuantityMetrics.map(\.identifier.rawValue)
      + HealthMetricDefinitions.sampleQuantityMetrics.map(\.identifier.rawValue)
      + HealthMetricDefinitions.categoryMetrics.map(\.identifier.rawValue)
    let types =
      HealthMetricDefinitions.sampleQuantityMetrics.map(\.type)
      + HealthMetricDefinitions.categoryMetrics.map(\.type)

    XCTAssertEqual(identifiers.count, Set(identifiers).count)
    XCTAssertEqual(types.count, Set(types).count)
  }
}
