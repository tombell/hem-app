import Foundation
import XCTest

@testable import Hem

final class HemWebClientTests: XCTestCase {
  func testEndpointRejectsEmptyText() {
    XCTAssertThrowsError(try HemWebEndpoint(text: "   ")) { error in
      XCTAssertEqual(error as? HemWebClientError, .missingEndpoint)
    }
  }

  func testEndpointRejectsInvalidURLText() {
    XCTAssertThrowsError(try HemWebEndpoint(text: "https://")) { error in
      XCTAssertEqual(error as? HemWebClientError, .invalidEndpoint)
    }
  }

  func testEndpointAppendsDefaultImportPathForHostOnlyEndpoint() throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")

    XCTAssertEqual(
      endpoint.importURL.absoluteString,
      "https://hem-web.local/apple-health/import"
    )
  }

  func testEndpointKeepsExplicitPath() throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local/custom/import")

    XCTAssertEqual(endpoint.importURL.path, "/custom/import")
  }

  func testEndpointRejectsNonHTTPURL() {
    XCTAssertThrowsError(try HemWebEndpoint(text: "file:///tmp/export.json")) { error in
      XCTAssertEqual(error as? HemWebClientError, .invalidEndpoint)
    }
  }

  func testEndpointTrimsAndDisplaysHost() throws {
    let endpoint = try HemWebEndpoint(text: "  https://hem-web.local/custom/import  ")

    XCTAssertEqual(endpoint.host, "hem-web.local")
  }

  func testPostInjectsBearerTokenAndJSONHeaders() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = MockHTTPSession(
      data: Data(#"{"ok":true}"#.utf8),
      response: try XCTUnwrap(
        HTTPURLResponse(
          url: endpoint.importURL,
          statusCode: 201,
          httpVersion: nil,
          headerFields: nil)
      )
    )
    let client = HemWebClient(session: session)

    try await client.post(
      payload: VitalsTestFixture.payload(),
      endpoint: endpoint,
      bearerToken: "secret-token"
    )

    XCTAssertEqual(session.request?.url, endpoint.importURL)
    XCTAssertEqual(session.request?.httpMethod, "POST")
    XCTAssertEqual(
      session.request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    XCTAssertEqual(session.request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    XCTAssertNotNil(session.request?.httpBody)
  }
}

private final class MockHTTPSession: HTTPSession {
  private let dataValue: Data
  private let responseValue: URLResponse
  private(set) var request: URLRequest?

  init(data: Data, response: URLResponse) {
    dataValue = data
    responseValue = response
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    return (dataValue, responseValue)
  }
}
