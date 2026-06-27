import SwiftUI

struct ExportHistoryPanel: View {
  let records: [ExportRecord]
  let retryAction: (UUID) async -> Void
  let viewAllAction: () -> Void

  var body: some View {
    DashboardPanel(title: "History", systemImage: "clock.arrow.circlepath", tint: .indigo) {
      if records.isEmpty {
        Text("No exports yet")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        ForEach(records.prefix(3)) { record in
          ExportHistoryRow(record: record, retryAction: retryAction)
          if record.id != records.prefix(3).last?.id {
            Divider()
          }
        }

        Button(action: viewAllAction) {
          Label("View All", systemImage: "list.bullet")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }
    }
  }
}

struct ExportHistorySheet: View {
  let records: [ExportRecord]
  let retryAction: (UUID) async -> Void
  let diagnosticsAction: (UUID) -> String?
  let deleteAction: (UUID) -> Void

  @State private var diagnosticsText: String?

  var body: some View {
    NavigationStack {
      List {
        ForEach(records) { record in
          ExportHistoryRow(record: record, retryAction: retryAction)
            .swipeActions(edge: .trailing) {
              Button("Delete", role: .destructive) {
                deleteAction(record.id)
              }
              Button("Diagnostics") {
                diagnosticsText = diagnosticsAction(record.id)
              }
            }
        }
      }
      .navigationTitle("Export History")
      .navigationBarTitleDisplayMode(.inline)
      .alert("Diagnostics", isPresented: diagnosticsBinding) {
        Button("OK", role: .cancel) {
          diagnosticsText = nil
        }
      } message: {
        Text(diagnosticsText ?? "")
      }
    }
  }

  private var diagnosticsBinding: Binding<Bool> {
    Binding(
      get: { diagnosticsText != nil },
      set: { isPresented in
        if !isPresented {
          diagnosticsText = nil
        }
      }
    )
  }
}

extension ExportStatus {
  fileprivate var title: String {
    switch self {
    case .sending:
      "Sending"
    case .succeeded:
      "Succeeded"
    case .failed:
      "Failed"
    case .queued:
      "Queued"
    }
  }

  fileprivate var systemImage: String {
    switch self {
    case .sending:
      "arrow.up.circle"
    case .succeeded:
      "checkmark.circle.fill"
    case .failed:
      "exclamationmark.triangle.fill"
    case .queued:
      "tray.and.arrow.down"
    }
  }

  fileprivate var tint: Color {
    switch self {
    case .sending:
      .blue
    case .succeeded:
      .green
    case .failed:
      .red
    case .queued:
      .orange
    }
  }
}

private struct ExportHistoryRow: View {
  let record: ExportRecord
  let retryAction: (UUID) async -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Label(record.status.title, systemImage: record.status.systemImage)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(record.status.tint)

        Spacer(minLength: 0)

        Text(record.range.displayLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(record.destinationHost)
        .font(.footnote)
        .foregroundStyle(.secondary)

      if let errorMessage = record.errorMessage,
        record.status == .failed || record.status == .queued
      {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      if record.status == .failed || record.status == .queued {
        LoadingActionButton(
          title: "Retry",
          systemImage: "arrow.clockwise",
          isLoading: false
        ) {
          await retryAction(record.id)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
    }
  }
}
