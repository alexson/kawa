import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBar: StatusBar!
  private let preferencesWindow = PreferencesWindowController()
  private var dockIconMonitor: Timer?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(PermanentStorage.hidesDockIcon ? .accessory : .regular)
    _ = ShortcutManager.shared
    statusBar = StatusBar { [weak self] in
      self?.showPreferences()
    }
    dockIconMonitor = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.synchronizeDockIconVisibility()
      }
    }
    if PermanentStorage.launchedForTheFirstTime {
      PermanentStorage.launchedForTheFirstTime = false
    }
    if !PermanentStorage.hidesDockIcon {
      DispatchQueue.main.async { [weak self] in
        self?.showPreferences()
      }
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      showPreferences()
    }
    return true
  }

  private func showPreferences() {
    if PermanentStorage.hidesDockIcon {
      NSApp.unhide(nil)
      NSApp.setActivationPolicy(.regular)
    }
    preferencesWindow.showAndActivate()
  }

  func setDockIconHidden(_ hidden: Bool) {
    PermanentStorage.hidesDockIcon = hidden
    if !hidden {
      NSApp.unhide(nil)
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
    } else if preferencesWindow.window?.isVisible != true {
      hideApplicationFromDock()
    }
  }

  fileprivate func hideApplicationFromDock() {
    guard PermanentStorage.hidesDockIcon else { return }
    NSApp.setActivationPolicy(.accessory)
    NSApp.hide(nil)
  }

  private func synchronizeDockIconVisibility() {
    guard PermanentStorage.hidesDockIcon else { return }
    guard preferencesWindow.window?.isVisible != true else { return }
    if NSApp.activationPolicy() != .accessory {
      NSApp.setActivationPolicy(.accessory)
    }
    if !NSApp.isHidden {
      NSApp.hide(nil)
    }
  }

  func openKawa() {
    setDockIconHidden(false)
    showPreferences()
  }

}

@MainActor
final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
  init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Kawa"
    window.center()
    window.isReleasedWhenClosed = false
    window.contentViewController = NSHostingController(rootView: SettingsView())
    super.init(window: window)
    window.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func showAndActivate() {
    NSApp.activate(ignoringOtherApps: true)
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
  }

  func windowWillClose(_ notification: Notification) {
    if PermanentStorage.hidesDockIcon {
      DispatchQueue.main.async {
        (NSApp.delegate as? AppDelegate)?.hideApplicationFromDock()
      }
      return
    }
    NSWorkspace.shared.menuBarOwningApplication?.activate(options: [])
  }
}
