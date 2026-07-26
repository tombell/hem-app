import Foundation
import Security

struct KeychainStore {
  private let service: String

  init(service: String = "dev.tombell.hem") {
    self.service = service
  }

  func save(_ value: String, account: String) throws {
    let data = Data(value.utf8)
    let query = baseQuery(account: account)

    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecSuccess {
      return
    }

    guard status == errSecItemNotFound else {
      throw KeychainStoreError.unhandledStatus(status)
    }

    var addQuery = query
    addQuery[kSecValueData as String] = data
    addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw KeychainStoreError.unhandledStatus(addStatus)
    }
  }

  func read(account: String) throws -> String? {
    var query = baseQuery(account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw KeychainStoreError.unhandledStatus(status)
    }

    guard let data = result as? Data,
      let string = String(data: data, encoding: .utf8)
    else {
      throw KeychainStoreError.invalidStoredValue
    }

    return string
  }

  func delete(account: String) throws {
    let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainStoreError.unhandledStatus(status)
    }
  }

  private func baseQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }
}

protocol KeychainStoring {
  func read(account: String) throws -> String?
  func save(_ value: String, account: String) throws
}

extension KeychainStore: KeychainStoring {}

enum KeychainStoreError: LocalizedError, Equatable {
  case unhandledStatus(OSStatus)
  case invalidStoredValue

  var errorDescription: String? {
    switch self {
    case .unhandledStatus(let status):
      "Keychain operation failed with status \(status)."
    case .invalidStoredValue:
      "The saved token could not be read from Keychain."
    }
  }
}
