import XCTest

@testable import Hem

final class HealthAuthorizationServiceTests: XCTestCase {
  func testReadTypesFingerprintChangesWithAuthorizationSurface() {
    let identifiers = HealthMetricDefinitions.readTypes.map(\.identifier).sorted()
    let expected = identifiers.joined(separator: "\n")

    XCTAssertEqual(HealthAuthorizationService.readTypesFingerprint, expected)
    XCTAssertFalse(expected.isEmpty)
  }
}
