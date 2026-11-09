import Foundation
import Observation

/// App state and actions shared by the Export, History, and Settings screens.
@MainActor
@Observable
final class AppModel {
  var endpointText = ""
  var bearerToken = ""
  var selectedStartDate: Date {
    didSet {
      let calendar = Calendar.exportDefault
      if calendar.startOfDay(for: selectedThroughDate)
        < calendar.startOfDay(for: selectedStartDate)
      {
        selectedThroughDate = selectedStartDate
      }
      saveDateRange()
    }
  }
  var selectedThroughDate: Date {
    didSet { saveDateRange() }
  }
  var selectedMetrics: Set<ExportMetricCategory> {
    didSet { metricSelectionStore.save(selectedMetrics) }
  }
  var preparedDraft: ExportDraft?

  private(set) var healthStatus: HealthAuthorizationService.Status = .unknown
  private(set) var records: [ExportRecord] = []
  private(set) var canExportSinceLastSuccess = false
  private(set) var lastResult: ExportDisplayResult?
  private(set) var settingsMessage: ExportDisplayResult?
  private(set) var isRequestingHealthAccess = false
  private(set) var isExporting = false
  private(set) var isTestingConnection = false

  @ObservationIgnored private let authorizationService = HealthAuthorizationService()
  @ObservationIgnored private let configurationStore = HemWebConfigurationStore()
  @ObservationIgnored private let dateRangeStore = ExportDateRangeStore()
  @ObservationIgnored private let metricSelectionStore = MetricSelectionStore()
  @ObservationIgnored private let exportCoordinator = ExportCoordinator()
  @ObservationIgnored private let hemWebClient = HemWebClient()

  init() {
    let dateRange = dateRangeStore.load(defaultRange: WeekRange.previousFullWeek())
    selectedStartDate = dateRange.startDate
    selectedThroughDate = dateRange.throughDate
    selectedMetrics = metricSelectionStore.load()
    endpointText = configurationStore.loadEndpointText()
    bearerToken = (try? configurationStore.loadBearerToken()) ?? ""
  }

  var selectedRange: WeekRange? {
    try? WeekRange.custom(from: selectedStartDate, through: selectedThroughDate)
  }

  var resolvedDestinationHost: String {
    resolvedEndpoint?.host ?? "Not configured"
  }

  var endpointState: ReadinessState {
    guard !trimmedEndpoint.isEmpty else {
      return .missing
    }

    return resolvedEndpoint == nil ? .invalid : .ready
  }

  var tokenState: ReadinessState {
    trimmedToken.isEmpty ? .missing : .ready
  }

  var healthState: ReadinessState {
    switch healthStatus {
    case .requested:
      .ready
    case .unavailable:
      .invalid
    case .unknown, .notRequested:
      .missing
    }
  }

  var canExport: Bool {
    endpointState == .ready && tokenState == .ready && healthState == .ready
      && !selectedMetrics.isEmpty
  }

  private var trimmedEndpoint: String {
    endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var trimmedToken: String {
    bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedEndpoint: HemWebEndpoint? {
    try? HemWebEndpoint(text: trimmedEndpoint)
  }

  /// Refreshes Health status, sends any queued exports that are due, and reloads history.
  func refresh() async {
    healthStatus = authorizationService.status()
    refreshRecords()
    await exportCoordinator.drainQueue()
    refreshRecords()
  }

  func refreshRecords() {
    records = (try? exportCoordinator.records()) ?? []
    canExportSinceLastSuccess = exportCoordinator.incrementalRange() != nil
  }

  func saveSettings() {
    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      settingsMessage = .success("Settings saved")
    } catch {
      settingsMessage = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  func testConnection() async {
    isTestingConnection = true
    defer { isTestingConnection = false }

    do {
      let endpoint = try HemWebEndpoint(text: endpointText)
      guard !trimmedToken.isEmpty else {
        throw HemWebClientError.missingToken
      }

      _ = try await hemWebClient.testConnection(endpoint: endpoint, bearerToken: trimmedToken)
      settingsMessage = .success("Connection verified")
    } catch {
      settingsMessage = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  func requestHealthAccess() async {
    isRequestingHealthAccess = true
    defer {
      isRequestingHealthAccess = false
      healthStatus = authorizationService.status()
    }

    do {
      try await authorizationService.requestAuthorization()
      lastResult = .success("Health access request completed")
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  func preparePreview() async {
    await runExport {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      let range = try WeekRange.custom(
        from: selectedStartDate,
        through: selectedThroughDate
      )
      preparedDraft = try await exportCoordinator.prepare(
        range: range,
        metrics: selectedMetrics
      )
      return nil
    }
  }

  func sendPreparedDraft() async {
    guard let preparedDraft else {
      return
    }

    await runExport {
      let summary = try await exportCoordinator.send(preparedDraft)
      self.preparedDraft = nil
      return summary
    }
  }

  func exportSinceLastSuccess() async {
    await runExport {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      return try await exportCoordinator.exportSinceLastSuccess(metrics: selectedMetrics)
    }
  }

  func retryExport(recordID: UUID) async {
    await runExport {
      try await exportCoordinator.retry(recordID: recordID)
    }
  }

  func diagnosticsText(recordID: UUID) -> String? {
    try? exportCoordinator.diagnostics(for: recordID)
  }

  func deleteRecord(recordID: UUID) async {
    do {
      try await exportCoordinator.deleteRecord(id: recordID)
      lastResult = .success("Export history item removed")
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
    refreshRecords()
  }

  /// Runs an export action with the shared progress state, then reports its outcome and reloads
  /// history. Actions that only prepare a preview return `nil` and clear the previous result.
  private func runExport(_ action: () async throws -> ExportSummary?) async {
    isExporting = true
    defer {
      isExporting = false
      refreshRecords()
    }

    do {
      lastResult = try await action().map { .success(successMessage(for: $0)) }
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  private func successMessage(for summary: ExportSummary) -> String {
    let status = summary.serverImportStatus?.rawValue ?? "accepted"
    return
      "Hem Web \(status) the \(summary.range.displayLabel) export from \(summary.destinationHost)"
  }

  private func saveDateRange() {
    dateRangeStore.save(startDate: selectedStartDate, throughDate: selectedThroughDate)
  }
}
