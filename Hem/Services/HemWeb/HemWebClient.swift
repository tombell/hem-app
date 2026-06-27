import Foundation

struct HemWebClient {
  private static func validate(data: Data, response: URLResponse) throws -> HemWebResponseSummary {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw HemWebClientError.nonHTTPResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      throw HemWebClientError.serverRejected(statusCode: httpResponse.statusCode)
    }

    guard !data.isEmpty else {
      return HemWebResponseSummary(statusCode: httpResponse.statusCode, bodySummary: nil)
    }

    if let response = try? JSONDecoder().decode(HemWebImportResponse.self, from: data),
      response.ok == false
    {
      throw HemWebClientError.rejectedResponse
    }

    return HemWebResponseSummary(
      statusCode: httpResponse.statusCode,
      bodySummary: String(data: data, encoding: .utf8)?.truncatedResponseSummary
    )
  }

  private let session: any HTTPSession

  init(session: any HTTPSession = URLSession.shared) {
    self.session = session
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
    return try Self.validate(data: data, response: response)
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
    return try Self.validate(data: data, response: response)
  }
}

protocol HTTPSession {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

enum HemWebClientError: LocalizedError, Equatable {
  case invalidEndpoint
  case missingEndpoint
  case missingToken
  case nonHTTPResponse
  case serverRejected(statusCode: Int)
  case rejectedResponse

  var errorDescription: String? {
    switch self {
    case .invalidEndpoint:
      "Enter a valid HTTP or HTTPS Hem Web backend endpoint."
    case .missingEndpoint:
      "Add a Hem Web backend endpoint URL before exporting."
    case .missingToken:
      "Add a Hem Web backend bearer token before exporting."
    case .nonHTTPResponse:
      "Hem Web backend returned a non-HTTP response."
    case .serverRejected(let statusCode):
      "Hem Web backend rejected the export with HTTP \(statusCode)."
    case .rejectedResponse:
      "Hem Web backend did not accept the export."
    }
  }
}

struct HemWebResponseSummary: Equatable {
  let statusCode: Int
  let bodySummary: String?
}

private struct HemWebImportResponse: Decodable {
  let ok: Bool
}

extension String {
  fileprivate var truncatedResponseSummary: String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count > 240 else {
      return trimmed
    }

    return String(trimmed.prefix(240))
  }
}
