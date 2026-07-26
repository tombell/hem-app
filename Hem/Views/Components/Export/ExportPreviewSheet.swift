import SwiftUI

struct ExportPreviewSheet: View {
  @Environment(\.dismiss) private var dismiss

  let draft: ExportDraft
  let isExporting: Bool
  let exportAction: () async -> Void

  var body: some View {
    NavigationStack {
      List {
        Section("Destination") {
          LabeledContent("Host", value: draft.destinationHost)
          LabeledContent("Range", value: draft.range.displayLabel)
          LabeledContent("Days", value: "\(draft.counts.dayCount)")
        }

        Section("Metrics") {
          Text(draft.metrics.map(\.title).joined(separator: ", "))
            .font(.body)
        }

        Section("Records") {
          LabeledContent("Daily rows", value: "\(draft.counts.dailyMetricCount)")
          LabeledContent("Samples", value: "\(draft.counts.sampleCount)")
          LabeledContent("Category samples", value: "\(draft.counts.categorySampleCount)")
          LabeledContent("Workouts", value: "\(draft.counts.workoutCount)")
          LabeledContent("Sleep", value: "\(draft.counts.sleepSampleCount)")
        }

        if !draft.warnings.isEmpty {
          Section("Warnings") {
            ForEach(draft.warnings, id: \.self) { warning in
              Label(warning, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("Preview Export")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task {
              await exportAction()
              dismiss()
            }
          } label: {
            if isExporting {
              ProgressView()
            } else {
              Text("Export")
            }
          }
          .disabled(isExporting)
        }
      }
    }
  }
}
