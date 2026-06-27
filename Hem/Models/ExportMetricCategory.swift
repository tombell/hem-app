import SwiftUI

enum ExportMetricCategory: String, CaseIterable, Codable, Identifiable, Hashable {
  case steps
  case energy
  case exercise
  case distance
  case heart
  case sleep
  case workouts
  case bodyMass
  case vitals
  case bodyComposition
  case mobility
  case nutrition
  case mindfulness
  case symptoms

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .steps:
      "Steps"
    case .energy:
      "Energy"
    case .exercise:
      "Exercise"
    case .distance:
      "Distance"
    case .heart:
      "Heart"
    case .sleep:
      "Sleep"
    case .workouts:
      "Workouts"
    case .bodyMass:
      "Body Mass"
    case .vitals:
      "Vitals"
    case .bodyComposition:
      "Body"
    case .mobility:
      "Mobility"
    case .nutrition:
      "Nutrition"
    case .mindfulness:
      "Mindfulness"
    case .symptoms:
      "Symptoms"
    }
  }

  var systemImage: String {
    switch self {
    case .steps:
      "figure.walk"
    case .energy:
      "flame"
    case .exercise:
      "timer"
    case .distance:
      "point.topleft.down.curvedto.point.bottomright.up"
    case .heart:
      "heart"
    case .sleep:
      "moon"
    case .workouts:
      "figure.run"
    case .bodyMass:
      "scalemass"
    case .vitals:
      "waveform.path.ecg"
    case .bodyComposition:
      "figure"
    case .mobility:
      "figure.walk.motion"
    case .nutrition:
      "fork.knife"
    case .mindfulness:
      "brain.head.profile"
    case .symptoms:
      "cross.case"
    }
  }

  var tint: Color {
    switch self {
    case .steps:
      .blue
    case .energy:
      .orange
    case .exercise:
      .green
    case .distance:
      .indigo
    case .heart:
      .red
    case .sleep:
      .purple
    case .workouts:
      .cyan
    case .bodyMass:
      .brown
    case .vitals:
      .pink
    case .bodyComposition:
      .teal
    case .mobility:
      .mint
    case .nutrition:
      .yellow
    case .mindfulness:
      .cyan
    case .symptoms:
      .red
    }
  }
}
