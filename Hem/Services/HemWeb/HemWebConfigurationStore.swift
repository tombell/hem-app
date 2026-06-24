import Foundation

struct HemWebConfiguration: Equatable {
  let endpoint: HemWebEndpoint
  let bearerToken: String
}

struct HemWebConfigurationStore {
  private let endpointKey = "dev.tombell.hem.hemWebEndpointURL"
  private let tokenAccount = "hemWebBearerToken"
  private let userDefaults: UserDefaults
  private let keychainStore: KeychainStore

  init(userDefaults: UserDefaults = .standard, keychainStore: KeychainStore = KeychainStore()) {
    self.userDefaults = userDefaults
    self.keychainStore = keychainStore
  }

  func load() throws -> HemWebConfiguration {
    let endpoint = try HemWebEndpoint(text: loadEndpointText())
    let token = try loadBearerToken().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty else {
      throw HemWebClientError.missingToken
    }

    return HemWebConfiguration(endpoint: endpoint, bearerToken: token)
  }

  func loadEndpointText() -> String {
    userDefaults.string(forKey: endpointKey) ?? ""
  }

  func loadBearerToken() throws -> String {
    try keychainStore.read(account: tokenAccount) ?? ""
  }

  func save(endpointText: String, bearerToken: String) throws {
    let trimmedEndpoint = endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedEndpoint.isEmpty {
      userDefaults.removeObject(forKey: endpointKey)
    } else {
      _ = try HemWebEndpoint(text: trimmedEndpoint)
      userDefaults.set(trimmedEndpoint, forKey: endpointKey)
    }

    let trimmedToken = bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedToken.isEmpty {
      try keychainStore.delete(account: tokenAccount)
    } else {
      try keychainStore.save(trimmedToken, account: tokenAccount)
    }
  }
}
