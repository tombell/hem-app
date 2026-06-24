import SwiftUI

struct ReadinessPanel: View {
  let endpointState: ReadinessState
  let tokenState: ReadinessState
  let healthState: ReadinessState

  var body: some View {
    HStack(spacing: 6) {
      ReadinessPill(title: "URL", state: endpointState)
      ReadinessPill(title: "Token", state: tokenState)
      ReadinessPill(title: "Health", state: healthState)
    }
  }
}
