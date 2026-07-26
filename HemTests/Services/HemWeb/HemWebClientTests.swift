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

  func testPostDecodesCreatedResponseAndInjectsSafeHeaders() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = try session(
      endpoint: endpoint,
      statusCode: 201,
      body: Self.importResponse(status: "created")
    )
    let client = HemWebClient(session: session)

    let summary = try await client.post(
      payload: VitalsTestFixture.payload(),
      endpoint: endpoint,
      bearerToken: "secret-token"
    )

    XCTAssertEqual(summary.statusCode, 201)
    XCTAssertEqual(summary.importResult?.importId, 42)
    XCTAssertEqual(summary.importResult?.status, .created)
    XCTAssertEqual(
      summary.importResult?.counts,
      HemWebImportCounts(
        categorySamples: 2,
        dailyMetrics: 4,
        samples: 1,
        sleep: 1,
        workouts: 1)
    )
    XCTAssertEqual(session.request?.url, endpoint.importURL)
    XCTAssertEqual(session.request?.httpMethod, "POST")
    XCTAssertEqual(
      session.request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    XCTAssertEqual(session.request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    XCTAssertNotNil(session.request?.httpBody)
  }

  func testPostDecodesDuplicateAndReplacedResponses() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")

    for status in [HemWebImportStatus.duplicate, .replaced] {
      let session = try session(
        endpoint: endpoint,
        statusCode: 200,
        body: Self.importResponse(status: status.rawValue)
      )

      let summary = try await HemWebClient(session: session).post(
        payload: VitalsTestFixture.payload(),
        endpoint: endpoint,
        bearerToken: "token"
      )

      XCTAssertEqual(summary.importResult?.status, status)
    }
  }

  func testPostRejectsMalformedSuccessfulResponse() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = try session(endpoint: endpoint, statusCode: 200, body: #"{"ok":true}"#)

    await assertThrowsErrorAsync(
      try await HemWebClient(session: session).post(
        payload: VitalsTestFixture.payload(),
        endpoint: endpoint,
        bearerToken: "token"
      )
    ) { error in
      XCTAssertEqual(error as? HemWebClientError, .malformedImportResponse)
    }
  }

  func testConnectionUsesAuthenticatedTestEndpoint() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local/apple-health/import")
    let session = try session(endpoint: endpoint, statusCode: 200, body: #"{"ok":true}"#)
    let client = HemWebClient(session: session)

    let summary = try await client.testConnection(
      endpoint: endpoint,
      bearerToken: "secret-token"
    )

    XCTAssertEqual(summary.statusCode, 200)
    XCTAssertNil(summary.importResult)
    XCTAssertEqual(session.request?.url, endpoint.testURL)
    XCTAssertEqual(session.request?.httpMethod, "GET")
    XCTAssertEqual(
      session.request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    XCTAssertNil(session.request?.httpBody)
  }

  func testConnectionRejectsMalformedSuccessfulResponse() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = try session(endpoint: endpoint, statusCode: 200, body: #"{"status":"ok"}"#)

    await assertThrowsErrorAsync(
      try await HemWebClient(session: session).testConnection(
        endpoint: endpoint,
        bearerToken: "token"
      )
    ) { error in
      XCTAssertEqual(error as? HemWebClientError, .malformedConnectionResponse)
    }
  }

  func testPostMapsStructuredPermanentErrors() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let cases: [(Int, String, String)] = [
      (400, "invalid_payload", "range is invalid"),
      (401, "auth", "Unauthorized"),
      (413, "body_too_large", "Request body too large"),
    ]

    for (statusCode, category, message) in cases {
      let session = try session(
        endpoint: endpoint,
        statusCode: statusCode,
        body: Self.errorResponse(category: category, message: message)
      )

      await assertThrowsErrorAsync(
        try await HemWebClient(session: session).post(
          payload: VitalsTestFixture.payload(),
          endpoint: endpoint,
          bearerToken: "token"
        )
      ) { error in
        XCTAssertEqual(
          error as? HemWebClientError,
          .serverRejected(
            statusCode: statusCode,
            category: category,
            message: message,
            retryAfter: nil)
        )
      }
    }
  }

  func testPostMapsRateLimitAndRetryAfter() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = try session(
      endpoint: endpoint,
      statusCode: 429,
      body: Self.errorResponse(category: "rate_limit", message: "Rate limit exceeded"),
      headers: ["Retry-After": "120"]
    )

    await assertThrowsErrorAsync(
      try await HemWebClient(session: session).post(
        payload: VitalsTestFixture.payload(),
        endpoint: endpoint,
        bearerToken: "token"
      )
    ) { error in
      XCTAssertEqual(
        error as? HemWebClientError,
        .serverRejected(
          statusCode: 429,
          category: "rate_limit",
          message: "Rate limit exceeded",
          retryAfter: 120)
      )
    }
  }

  func testPostMapsServerErrorWithoutLeakingRequestData() async throws {
    let endpoint = try HemWebEndpoint(text: "https://hem-web.local")
    let session = try session(
      endpoint: endpoint,
      statusCode: 500,
      body: Self.errorResponse(category: "server_error", message: "Import failed")
    )

    await assertThrowsErrorAsync(
      try await HemWebClient(session: session).post(
        payload: VitalsTestFixture.payload(),
        endpoint: endpoint,
        bearerToken: "secret-token"
      )
    ) { error in
      let clientError = error as? HemWebClientError
      XCTAssertEqual(clientError?.statusCode, 500)
      XCTAssertFalse(clientError?.errorDescription?.contains("secret-token") ?? true)
      XCTAssertFalse(clientError?.errorDescription?.contains("generatedAt") ?? true)
    }
  }

  private static func errorResponse(category: String, message: String) -> String {
    """
    {"ok":false,"error":{"category":"\(category)","message":"\(message)"}}
    """
  }

  private static func importResponse(status: String) -> String {
    """
    {
      "ok": true,
      "importId": 42,
      "status": "\(status)",
      "counts": {
        "categorySamples": 2,
        "dailyMetrics": 4,
        "samples": 1,
        "sleep": 1,
        "workouts": 1
      }
    }
    """
  }

  private func session(
    endpoint: HemWebEndpoint,
    statusCode: Int,
    body: String,
    headers: [String: String]? = nil
  ) throws -> MockHTTPSession {
    MockHTTPSession(
      data: Data(body.utf8),
      response: try XCTUnwrap(
        HTTPURLResponse(
          url: endpoint.importURL,
          statusCode: statusCode,
          httpVersion: nil,
          headerFields: headers)
      )
    )
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

private func assertThrowsErrorAsync<T>(
  _ expression: @autoclosure () async throws -> T,
  _ errorHandler: (Error) -> Void,
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  do {
    _ = try await expression()
    XCTFail("Expected expression to throw.", file: file, line: line)
  } catch {
    errorHandler(error)
  }
}
