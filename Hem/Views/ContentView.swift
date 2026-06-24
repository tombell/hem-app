import SwiftUI

struct ContentView: View {
  private static let initialRange = WeekRange.previousFullWeek()
  private static let initialThroughDate =
    Calendar.vitalsDefault.date(
      byAdding: .day,
      value: -1,
      to: initialRange.end
    ) ?? initialRange.start

  @State private var endpointText = ""
  @State private var bearerToken = ""
  @State private var healthStatus: HealthAuthorizationService.Status = .unknown
  @State private var settingsMessage: ExportDisplayResult?
  @State private var lastResult: ExportDisplayResult?
  @State private var isRequestingHealthAccess = false
  @State private var isExporting = false
  @State private var selectedStartDate = ContentView.initialRange.start
  @State private var selectedThroughDate = ContentView.initialThroughDate
  @State private var selectedTab: AppTab = .export

  var body: some View {
    TabView(selection: $selectedTab) {
      ExportScreen(
        rangeLabel: selectedRange.displayLabel,
        endpointState: endpointState,
        tokenState: tokenState,
        healthState: healthState,
        selectedStartDate: $selectedStartDate,
        selectedThroughDate: $selectedThroughDate,
        isExporting: isExporting,
        result: lastResult,
        exportAction: exportNow
      )
      .tabItem { AppTab.export.label }
      .tag(AppTab.export)

      SettingsScreen(
        endpointText: $endpointText,
        bearerToken: $bearerToken,
        destinationHost: resolvedDestinationHost,
        endpointState: endpointState,
        healthStatus: healthStatus,
        healthState: healthState,
        settingsMessage: settingsMessage,
        isRequestingHealthAccess: isRequestingHealthAccess,
        result: lastResult,
        saveAction: saveSettings,
        requestHealthAccessAction: requestHealthAccess
      )
      .tabItem { AppTab.settings.label }
      .tag(AppTab.settings)
    }
    .task {
      loadSettings()
      refreshHealthStatus()
    }
    .onChange(of: selectedStartDate) { _, newStartDate in
      let calendar = Calendar.vitalsDefault
      if calendar.startOfDay(for: selectedThroughDate) < calendar.startOfDay(for: newStartDate) {
        selectedThroughDate = newStartDate
      }
    }
  }

  private let authorizationService = HealthAuthorizationService()
  private let configurationStore = HemWebConfigurationStore()
  private let exportRunner = HealthExportRunner()

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

  private func loadSettings() {
    endpointText = configurationStore.loadEndpointText()
    bearerToken = (try? configurationStore.loadBearerToken()) ?? ""
  }

  private func saveSettings() {
    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      settingsMessage = .success("Settings saved")
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

  private func exportNow() async {
    isExporting = true
    defer { isExporting = false }

    do {
      try configurationStore.save(endpointText: endpointText, bearerToken: bearerToken)
      let range = try WeekRange.custom(from: selectedStartDate, through: selectedThroughDate)
      let summary = try await exportRunner.export(range: range)
      lastResult = .success(
        "Exported \(summary.range.displayLabel) to \(summary.destinationHost)")
    } catch {
      lastResult = .failure(ExportErrorPresentation.message(for: error))
    }
  }
}

#Preview {
  ContentView()
}
