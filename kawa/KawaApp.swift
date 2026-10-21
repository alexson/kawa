import SwiftUI

@main
struct KawaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
        .frame(minWidth: 560, minHeight: 400)
    }
  }
}
