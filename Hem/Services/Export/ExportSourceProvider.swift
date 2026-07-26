import Foundation

#if canImport(UIKit)
  import UIKit
#endif

struct ExportSourceProvider {
  private let bundle: Bundle
  private let deviceIdentifierStore: ExportDeviceIdentifierStore

  init(
    bundle: Bundle = .main,
    deviceIdentifierStore: ExportDeviceIdentifierStore = ExportDeviceIdentifierStore()
  ) {
    self.bundle = bundle
    self.deviceIdentifierStore = deviceIdentifierStore
  }

  @MainActor
  func current() throws -> ExportPayload.Source {
    let deviceIdentifier = try deviceIdentifierStore.identifier()

    #if canImport(UIKit)
      let device = UIDevice.current
      return ExportPayload.Source(
        app: "Hem",
        bundleIdentifier: bundle.bundleIdentifier ?? "dev.tombell.hem",
        deviceIdentifier: deviceIdentifier,
        deviceName: device.name,
        deviceSystemName: device.systemName,
        deviceSystemVersion: device.systemVersion
      )
    #else
      return ExportPayload.Source(
        app: "Hem",
        bundleIdentifier: bundle.bundleIdentifier ?? "dev.tombell.hem",
        deviceIdentifier: deviceIdentifier,
        deviceName: Host.current().localizedName ?? "Unknown",
        deviceSystemName: "Unknown",
        deviceSystemVersion: ProcessInfo.processInfo.operatingSystemVersionString
      )
    #endif
  }
}

struct ExportDeviceIdentifierStore {
  static let account = "exportDeviceIdentifier"

  private let keychainStore: any KeychainStoring
  private let uuid: () -> UUID

  init(
    keychainStore: any KeychainStoring = KeychainStore(),
    uuid: @escaping () -> UUID = UUID.init
  ) {
    self.keychainStore = keychainStore
    self.uuid = uuid
  }

  func identifier() throws -> String {
    if let storedIdentifier = try keychainStore.read(account: Self.account),
      !storedIdentifier.isEmpty
    {
      return storedIdentifier
    }

    let identifier = uuid().uuidString
    try keychainStore.save(identifier, account: Self.account)
    return identifier
  }
}
