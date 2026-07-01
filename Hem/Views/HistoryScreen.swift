import SwiftUI

struct HistoryScreen: View {
  let records: [ExportRecord]
  let retryAction: (UUID) async -> Void
  let diagnosticsAction: (UUID) -> String?
  let deleteAction: (UUID) -> Void

  @State private var diagnosticsText: String?

  var body: some View {
    NavigationStack {
      Group {
        if records.isEmpty {
          ContentUnavailableView(
            "No exports yet",
            systemImage: "clock.arrow.circlepath",
            description: Text("Completed, queued, and failed exports will appear here.")
          )
        } else {
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
                .contentShape(Rectangle())
            }
          }
          .listStyle(.insetGrouped)
        }
      }
      .navigationTitle("History")
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

#Preview {
  HistoryScreen(
    records: [
      ExportRecord(
        id: UUID(),
        range: WeekRange.previousDay(),
        mode: .shortcut,
        metrics: ExportMetricCategory.allCases,
        status: .succeeded,
        destinationHost: "hem-web.local",
        endpointURLString: "https://hem-web.local/apple-health/import",
        requestedAt: Date(),
        startedAt: Date(),
        completedAt: Date(),
        attemptCount: 1,
        counts: .empty,
        retrySourceID: nil,
        payloadFileName: nil,
        errorMessage: nil,
        errorCode: nil,
        httpStatus: 201,
        serverResponseSummary: nil
      ),
      ExportRecord(
        id: UUID(),
        range: WeekRange.previousFullWeek(),
        mode: .manual,
        metrics: ExportMetricCategory.allCases,
        status: .queued,
        destinationHost: "hem-web.local",
        endpointURLString: "https://hem-web.local/apple-health/import",
        requestedAt: Date(),
        startedAt: Date(),
        completedAt: nil,
        attemptCount: 1,
        counts: .empty,
        retrySourceID: nil,
        payloadFileName: "queued.json",
        errorMessage: "The network connection was lost.",
        errorCode: "URLError",
        httpStatus: nil,
        serverResponseSummary: nil
      ),
    ],
    retryAction: { _ in },
    diagnosticsAction: { _ in "No diagnostics" },
    deleteAction: { _ in }
  )
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

extension ExportMode {
  fileprivate var historyTitle: String {
    switch self {
    case .manual:
      "Manual"
    case .retry:
      "Retry"
    case .incremental:
      "Since last success"
    case .shortcut:
      "Shortcut"
    }
  }

  fileprivate var historySystemImage: String {
    switch self {
    case .manual:
      "hand.tap"
    case .retry:
      "arrow.clockwise"
    case .incremental:
      "clock.arrow.circlepath"
    case .shortcut:
      "sparkles"
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

        Label("For \(record.range.displayLabel)", systemImage: "calendar")
          .font(.caption)
          .foregroundStyle(.secondary)
          .labelStyle(.titleAndIcon)
      }

      HStack(spacing: 8) {
        Label(record.mode.historyTitle, systemImage: record.mode.historySystemImage)
        Text(record.destinationHost)
      }
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
