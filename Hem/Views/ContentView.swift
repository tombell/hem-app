import SwiftUI

struct ContentView: View {
  private static let initialRange = WeekRange.previousFullWeek()
  private static let initialThroughDate =
    Calendar.vitalsDefault.date(
      byAdding: .day,
      value: -1,
      to: initialRange.end
    ) ?? initialRange.start

  @Environment(\.scenePhase) private var scenePhase

  @State private var endpointText = ""
  @State private var bearerToken = ""
  @State private var healthStatus: HealthAuthorizationService.Status = .unknown
  @State private var settingsMessage: ExportDisplayResult?
  @State private var lastResult: ExportDisplayResult?
  @State private var isRequestingHealthAccess = false
  @State private var isPreparingExport = false
  @State private var isExporting = false
  @State private var isTestingConnection = false
  @State private var selectedStartDate: Date
  @State private var selectedThroughDate: Date
  @State private var selectedMetrics = Set(ExportMetricCategory.allCases)
  @State private var records: [ExportRecord] = []
  @State private var preparedDraft: ExportDraft?
  @State private var selectedTab: AppTab = .export

  init(dateRangeStore: ExportDateRangeStore = ExportDateRangeStore()) {
    self.dateRangeStore = dateRangeStore
    let dateRange = dateRangeStore.load(defaultRange: Self.initialRange)
    _selectedStartDate = State(initialValue: dateRange.startDate)
    _selectedThroughDate = State(initialValue: dateRange.throughDate)
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      ExportScreen(
        rangeLabel: selectedRange.displayLabel,
        endpointState: endpointState,
        tokenState: tokenState,
        healthState: healthState,
        selectedStartDate: $selectedStartDate,
        selectedThroughDate: $selectedThroughDate,
        selectedMetrics: $selectedMetrics,
        isPreparing: isPreparingExport || isExporting,
        canExport: canExport,
        canExportSinceLastSuccess: canExportSinceLastSuccess,
        result: lastResult,
        previewAction: preparePreview,
        incrementalAction: exportSinceLastSuccess
      )
      .tabItem { AppTab.export.label }
      .tag(AppTab.export)

      HistoryScreen(
        records: records,
        retryAction: retryExport,
        diagnosticsAction: diagnosticsText,
        deleteAction: deleteRecord
      )
      .tabItem { AppTab.history.label }
      .tag(AppTab.history)

      SettingsScreen(
        endpointText: $endpointText,
        bearerToken: $bearerToken,
        destinationHost: resolvedDestinationHost,
        endpointState: endpointState,
        healthStatus: healthStatus,
        healthState: healthState,
        settingsMessage: settingsMessage,
        isRequestingHealthAccess: isRequestingHealthAccess,
        isTestingConnection: isTestingConnection,
        result: lastResult,
        saveAction: saveSettings,
        testConnectionAction: testConnection,
        requestHealthAccessAction: requestHealthAccess
      )
      .tabItem { AppTab.settings.label }
      .tag(AppTab.settings)
    }
    .task {
      loadSettings()
      loadMetrics()
      refreshRecords()
      refreshHealthStatus()
      await exportCoordinator.drainQueue()
      refreshRecords()
    }
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active else {
        return
      }

      Task {
        await exportCoordinator.drainQueue()
        refreshRecords()
      }
    }
    .onChange(of: selectedTab) { _, newTab in
      guard newTab == .history else {
        return
      }

      refreshRecords()
    }
    .onChange(of: selectedStartDate) { _, newStartDate in
      let calendar = Calendar.vitalsDefault
      var throughDate = selectedThroughDate
      if calendar.startOfDay(for: selectedThroughDate) < calendar.startOfDay(for: newStartDate) {
        throughDate = newStartDate
        selectedThroughDate = throughDate
      }
      dateRangeStore.save(startDate: newStartDate, throughDate: throughDate)
    }
    .onChange(of: selectedThroughDate) { _, newThroughDate in
      dateRangeStore.save(startDate: selectedStartDate, throughDate: newThroughDate)
    }
    .onChange(of: selectedMetrics) { _, newMetrics in
      metricSelectionStore.save(newMetrics)
    }
    .sheet(item: $preparedDraft) { draft in
      ExportPreviewSheet(
        draft: draft,
        isExporting: isExporting
      ) {
        await sendPreparedDraft()
      }
    }
  }

  private let authorizationService = HealthAuthorizationService()
  private let configurationStore = HemWebConfigurationStore()
  private let dateRangeStore: ExportDateRangeStore
  private let metricSelectionStore = MetricSelectionStore()
  private let exportCoordinator = ExportCoordinator()
  private let hemWebClient = HemWebClient()

  private var selectedRange: WeekRange {
    (try? WeekRange.custom(from: selectedStartDate, through: selectedThroughDate))
      ?? Self.initialRange
  }

  private var trimmedEndpoint: String {
    endpointText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var trimmedToken: String {
    bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var resolvedDestinationHost: String {
    resolvedEndpoint?.host ?? "Not configured"
  }

  private var resolvedEndpoint: HemWebEndpoint? {
    try? HemWebEndpoint(text: trimmedEndpoint)
  }

  private var endpointState: ReadinessState {
    guard !trimmedEndpoint.isEmpty else {
      return .missing
    }

    return resolvedEndpoint == nil ? .invalid : .ready
  }

  private var tokenState: ReadinessState {
    trimmedToken.isEmpty ? .missing : .ready
  }

  private var healthState: ReadinessState {
    switch healthStatus {
    case .requested:
      .ready
    case .unavailable:
      .invalid
    case .unknown, .notRequested:
      .missing
    }
  }

  private var canExport: Bool {
    endpointState == .ready && tokenState == .ready && healthState == .ready
      && !selectedMetrics.isEmpty
  }

  private var canExportSinceLastSuccess: Bool {
    exportCoordinator.incrementalRange() != nil
  }

  private func loadSettings() {
    endpointText = configurationStore.loadEndpointText()
    bearerToken = (try? configurationStore.loadBearerToken()) ?? ""
  }

  private func loadMetrics() {
    selectedMetrics = metricSelectionStore.load()
  }

  private func refreshRecords() {
    records = (try? exportCoordinator.records()) ?? []
  }

  private func saveSettings() {
    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      settingsMessage = .success("Settings saved")
    } catch {
      settingsMessage = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  private func testConnection() async {
    isTestingConnection = true
    defer { isTestingConnection = false }

    do {
      let endpoint = try HemWebEndpoint(text: endpointText)
      let token = trimmedToken
      guard !token.isEmpty else {
        throw HemWebClientError.missingToken
      }

      _ = try await hemWebClient.testConnection(endpoint: endpoint, bearerToken: token)
      settingsMessage = .success("Connection verified")
    } catch {
      settingsMessage = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  private func refreshHealthStatus() {
    healthStatus = authorizationService.status()
  }

  private func requestHealthAccess() async {
    isRequestingHealthAccess = true
    defer {
      isRequestingHealthAccess = false
      refreshHealthStatus()
    }

    do {
      try await authorizationService.requestAuthorization()
      lastResult = .success("Health access request completed")
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  private func preparePreview() async {
    isPreparingExport = true
    defer { isPreparingExport = false }

    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      let range = try WeekRange.custom(from: selectedStartDate, through: selectedThroughDate)
      preparedDraft = try await exportCoordinator.prepare(
        range: range,
        metrics: selectedMetrics
      )
      lastResult = nil
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }

  private func sendPreparedDraft() async {
    guard let preparedDraft else {
      return
    }

    isExporting = true
    defer { isExporting = false }

    do {
      let summary = try await exportCoordinator.send(preparedDraft)
      lastResult = .success(
        "Exported \(summary.range.displayLabel) to \(summary.destinationHost)")
      self.preparedDraft = nil
      refreshRecords()
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
      refreshRecords()
    }
  }

  private func exportSinceLastSuccess() async {
    isPreparingExport = true
    defer { isPreparingExport = false }

    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      let summary = try await exportCoordinator.exportSinceLastSuccess(metrics: selectedMetrics)
      lastResult = .success(
        "Exported \(summary.range.displayLabel) to \(summary.destinationHost)")
      refreshRecords()
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
      refreshRecords()
    }
  }

  private func retryExport(recordID: UUID) async {
    isPreparingExport = true
    defer { isPreparingExport = false }

    do {
      let summary = try await exportCoordinator.retry(recordID: recordID)
      lastResult = .success(
        "Exported \(summary.range.displayLabel) to \(summary.destinationHost)")
      refreshRecords()
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
      refreshRecords()
    }
  }

  private func diagnosticsText(recordID: UUID) -> String? {
    try? exportCoordinator.diagnostics(for: recordID).text
  }

  private func deleteRecord(recordID: UUID) {
    do {
      try exportCoordinator.deleteRecord(id: recordID)
      refreshRecords()
      lastResult = .success("Export history item removed")
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }
}

#Preview {
  ContentView()
}
