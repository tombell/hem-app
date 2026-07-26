import Foundation

struct HemWebClient {
  private let now: () -> Date
  private let session: any HTTPSession

  init(
    session: any HTTPSession = URLSession.shared,
    now: @escaping () -> Date = Date.init
  ) {
    self.session = session
    self.now = now
  }

  func post(
    payload: ExportPayload,
    endpoint: HemWebEndpoint,
    bearerToken: String
  ) async throws -> HemWebResponseSummary {
    let body = try ExportPayloadEncoding.encode(payload)

    var request = URLRequest(url: endpoint.importURL)
    request.httpMethod = "POST"
    request.httpBody = body
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await session.data(for: request)
    return try validateImport(data: data, response: response)
  }

  func testConnection(
    endpoint: HemWebEndpoint,
    bearerToken: String
  ) async throws -> HemWebResponseSummary {
    var request = URLRequest(url: endpoint.testURL)
    request.httpMethod = "GET"
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await session.data(for: request)
    return try validateConnection(data: data, response: response)
  }

  private func validateConnection(data: Data, response: URLResponse) throws
    -> HemWebResponseSummary
  {
    let httpResponse = try validatedHTTPResponse(data: data, response: response)
    guard let result = try? JSONDecoder().decode(HemWebConnectionResponse.self, from: data),
      result.ok
    else {
      throw HemWebClientError.malformedConnectionResponse
    }

    return HemWebResponseSummary(statusCode: httpResponse.statusCode)
  }

  private func validateImport(data: Data, response: URLResponse) throws -> HemWebResponseSummary {
    let httpResponse = try validatedHTTPResponse(data: data, response: response)
    guard let result = try? JSONDecoder().decode(HemWebImportResult.self, from: data),
      result.ok
    else {
      throw HemWebClientError.malformedImportResponse
    }

    return HemWebResponseSummary(
      statusCode: httpResponse.statusCode,
      importResult: result
    )
  }

  private func validatedHTTPResponse(data: Data, response: URLResponse) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw HemWebClientError.nonHTTPResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let errorResponse = try? JSONDecoder().decode(HemWebErrorResponse.self, from: data)
      throw HemWebClientError.serverRejected(
        statusCode: httpResponse.statusCode,
        category: errorResponse?.error.category,
        message: errorResponse?.error.message,
        retryAfter: retryAfter(from: httpResponse)
      )
    }

    return httpResponse
  }

  private func retryAfter(from response: HTTPURLResponse) -> TimeInterval? {
    guard
      let value = response.value(forHTTPHeaderField: "Retry-After")?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !value.isEmpty
    else {
      return nil
    }

    if let seconds = TimeInterval(value), seconds >= 0 {
      return seconds
    }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
    guard let date = formatter.date(from: value) else {
      return nil
    }

    return max(0, date.timeIntervalSince(now()))
  }
}

protocol HTTPSession {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

enum HemWebClientError: LocalizedError, Equatable {
  case invalidEndpoint
  case malformedConnectionResponse
  case malformedImportResponse
  case missingEndpoint
  case missingToken
  case nonHTTPResponse
  case serverRejected(
    statusCode: Int,
    category: String?,
    message: String?,
    retryAfter: TimeInterval?
  )

  var errorDescription: String? {
    switch self {
    case .invalidEndpoint:
      "Enter a valid HTTP or HTTPS Hem Web backend endpoint."
    case .malformedConnectionResponse:
      "Hem Web returned an invalid connection-test response."
    case .malformedImportResponse:
      "Hem Web returned an invalid import response."
    case .missingEndpoint:
      "Add a Hem Web backend endpoint URL before exporting."
    case .missingToken:
      "Add a Hem Web backend bearer token before exporting."
    case .nonHTTPResponse:
      "Hem Web backend returned a non-HTTP response."
    case .serverRejected(let statusCode, _, let message, let retryAfter):
      switch statusCode {
      case 400:
        "Hem Web rejected the export payload\(message.map { ": \($0)" } ?? ".")"
      case 401:
        "Hem Web authentication failed. Check the bearer token."
      case 413:
        "The export is too large for Hem Web. Choose a shorter date range or fewer metrics."
      case 429:
        if let retryAfter {
          "Hem Web rate limited the request. Try again in \(Int(retryAfter.rounded(.up))) seconds."
        } else {
          "Hem Web rate limited the request. Try again later."
        }
      case 500..<600:
        "Hem Web is temporarily unavailable (HTTP \(statusCode)). The export will be retried."
      default:
        "Hem Web rejected the request with HTTP \(statusCode)\(message.map { ": \($0)" } ?? ".")"
      }
    }
  }

  var retryAfter: TimeInterval? {
    guard case .serverRejected(_, _, _, let retryAfter) = self else {
      return nil
    }
    return retryAfter
  }

  var statusCode: Int? {
    guard case .serverRejected(let statusCode, _, _, _) = self else {
      return nil
    }
    return statusCode
  }
}

struct HemWebResponseSummary: Equatable {
  let statusCode: Int
  let importResult: HemWebImportResult?

  init(statusCode: Int, importResult: HemWebImportResult? = nil) {
    self.statusCode = statusCode
    self.importResult = importResult
  }
}

struct HemWebImportResult: Codable, Equatable {
  let ok: Bool
  let importId: Int
  let status: HemWebImportStatus
  let counts: HemWebImportCounts
}

enum HemWebImportStatus: String, Codable, Equatable {
  case created
  case duplicate
  case replaced
}

struct HemWebImportCounts: Codable, Equatable {
  let categorySamples: Int
  let dailyMetrics: Int
  let samples: Int
  let sleep: Int
  let workouts: Int
}

private struct HemWebConnectionResponse: Decodable {
  let ok: Bool
}

private struct HemWebErrorResponse: Decodable {
  struct Details: Decodable {
    let category: String
    let message: String
  }

  let ok: Bool
  let error: Details
}
