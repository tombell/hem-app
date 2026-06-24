import Foundation

#if canImport(UIKit)
  import UIKit
#endif

struct ExportSourceProvider {
  private let bundle: Bundle

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  @MainActor
  func current() -> ExportPayload.Source {
    #if canImport(UIKit)
      let device = UIDevice.current
      return ExportPayload.Source(
        app: "Hem",
        bundleIdentifier: bundle.bundleIdentifier ?? "dev.tombell.hem",
        deviceName: device.name,
        deviceSystemName: device.systemName,
        deviceSystemVersion: device.systemVersion
      )
    #else
      return ExportPayload.Source(
        app: "Hem",
        bundleIdentifier: bundle.bundleIdentifier ?? "dev.tombell.hem",
        deviceName: Host.current().localizedName ?? "Unknown",
        deviceSystemName: "Unknown",
        deviceSystemVersion: ProcessInfo.processInfo.operatingSystemVersionString
      )
    #endif
  }
}
