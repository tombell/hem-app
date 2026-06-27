import Foundation

struct HemWebEndpoint: Equatable {
  let endpointURL: URL
  let importURL: URL

  var host: String {
    importURL.host ?? "Hem Web"
  }

  var testURL: URL {
    importURL.appendingPathComponent("test")
  }

  init(text: String) throws {
    let trimmedEndpoint = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedEndpoint.isEmpty else {
      throw HemWebClientError.missingEndpoint
    }

    guard let endpointURL = URL(string: trimmedEndpoint) else {
      throw HemWebClientError.invalidEndpoint
    }

    try self.init(endpointURL: endpointURL)
  }

  init(endpointURL: URL) throws {
    guard let scheme = endpointURL.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      endpointURL.host != nil
    else {
      throw HemWebClientError.invalidEndpoint
    }

    var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)
    let path = components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
    if path.isEmpty {
      components?.path = "/apple-health/import"
    }

    guard let importURL = components?.url else {
      throw HemWebClientError.invalidEndpoint
    }

    self.endpointURL = endpointURL
    self.importURL = importURL
  }
}
