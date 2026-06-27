import Foundation

struct ExportHistoryStore: ExportHistoryStoring {
  private let baseURL: URL
  private let recordsURL: URL
  private let payloadsURL: URL
  private let fileManager: FileManager

  init(
    baseURL: URL? = nil,
    fileManager: FileManager = .default
  ) {
    self.fileManager = fileManager
    let resolvedBaseURL =
      baseURL
      ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Hem", isDirectory: true)
    self.baseURL = resolvedBaseURL
    recordsURL = resolvedBaseURL.appendingPathComponent("ExportHistory.json")
    payloadsURL = resolvedBaseURL.appendingPathComponent("QueuedPayloads", isDirectory: true)
  }

  func loadRecords() throws -> [ExportRecord] {
    guard fileManager.fileExists(atPath: recordsURL.path) else {
      return []
    }

    let data = try Data(contentsOf: recordsURL)
    return try JSONDecoder.exportStore.decode([ExportRecord].self, from: data)
      .sorted { $0.requestedAt > $1.requestedAt }
  }

  func saveRecords(_ records: [ExportRecord]) throws {
    try ensureDirectories()
    let sortedRecords = records.sorted { $0.requestedAt > $1.requestedAt }
    let data = try JSONEncoder.exportStore.encode(sortedRecords)
    try writeAtomically(data, to: recordsURL)
  }

  func savePayload(_ payload: ExportPayload, named fileName: String) throws {
    try ensureDirectories()
    let data = try ExportPayloadEncoding.encode(payload)
    try writeAtomically(data, to: payloadsURL.appendingPathComponent(fileName))
  }

  func loadPayload(named fileName: String) throws -> ExportPayload {
    let data = try Data(contentsOf: payloadsURL.appendingPathComponent(fileName))
    return try ExportDateFormatting.jsonDecoder.decode(ExportPayload.self, from: data)
  }

  func deletePayload(named fileName: String) throws {
    let url = payloadsURL.appendingPathComponent(fileName)
    guard fileManager.fileExists(atPath: url.path) else {
      return
    }

    try fileManager.removeItem(at: url)
  }

  func deleteAll() throws {
    if fileManager.fileExists(atPath: recordsURL.path) {
      try fileManager.removeItem(at: recordsURL)
    }

    if fileManager.fileExists(atPath: payloadsURL.path) {
      try fileManager.removeItem(at: payloadsURL)
    }
  }

  private func ensureDirectories() throws {
    try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: payloadsURL, withIntermediateDirectories: true)
  }

  private func writeAtomically(_ data: Data, to url: URL) throws {
    let temporaryURL = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent).tmp")
    try data.write(to: temporaryURL, options: .atomic)
    if fileManager.fileExists(atPath: url.path) {
      _ = try fileManager.replaceItemAt(url, withItemAt: temporaryURL)
    } else {
      try fileManager.moveItem(at: temporaryURL, to: url)
    }
  }
}

protocol ExportHistoryStoring {
  func loadRecords() throws -> [ExportRecord]
  func saveRecords(_ records: [ExportRecord]) throws
  func savePayload(_ payload: ExportPayload, named fileName: String) throws
  func loadPayload(named fileName: String) throws -> ExportPayload
  func deletePayload(named fileName: String) throws
  func deleteAll() throws
}

extension JSONEncoder {
  static var exportStore: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }
}

extension JSONDecoder {
  static var exportStore: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
