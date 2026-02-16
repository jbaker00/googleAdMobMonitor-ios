import SwiftUI

@main
struct GoogleAdMobMonitorApp: App {
  @StateObject private var viewModel = StatsViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(viewModel)
    }
  }
}
