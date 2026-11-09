import SwiftUI

struct ContentView: View {
  @Environment(\.scenePhase) private var scenePhase

  @State private var model = AppModel()
  @State private var selectedTab: AppTab = .export

  var body: some View {
    TabView(selection: $selectedTab) {
      ExportScreen()
        .tabItem { AppTab.export.label }
        .tag(AppTab.export)

      HistoryScreen(
        records: model.records,
        retryAction: model.retryExport,
        diagnosticsAction: model.diagnosticsText,
        deleteAction: model.deleteRecord
      )
      .tabItem { AppTab.history.label }
      .tag(AppTab.history)

      SettingsScreen()
        .tabItem { AppTab.settings.label }
        .tag(AppTab.settings)
    }
    .environment(model)
    .onChange(of: scenePhase, initial: true) { _, newPhase in
      guard newPhase == .active else {
        return
      }

      Task {
        await model.refresh()
      }
    }
    .onChange(of: selectedTab) { _, newTab in
      if newTab == .history {
        model.refreshRecords()
      }
    }
    .sheet(item: $model.preparedDraft) { draft in
      ExportPreviewSheet(draft: draft, isExporting: model.isExporting) {
        await model.sendPreparedDraft()
      }
    }
  }
}

#Preview {
  ContentView()
}
