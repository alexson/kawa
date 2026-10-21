import AppKit

@MainActor
final class StatusBar {
  private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

  init(openPreferences: @escaping () -> Void) {
    guard let button = item.button else { return }
    let image = NSImage(named: "StatusItemIcon")
    image?.isTemplate = true
    button.image = image
    button.title = "Kawa"
    button.toolTip = "Open Kawa settings"
    button.target = self
    button.action = #selector(openSettings)
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    self.openPreferences = openPreferences
    item.isVisible = true
    applyDisplayMode(PermanentStorage.menuBarDisplayMode)
  }

  private var openPreferences: (() -> Void)?

  @objc private func openSettings() {
    if NSApp.currentEvent?.type == .rightMouseUp {
      showContextMenu()
      return
    }
    openPreferences?()
  }

  func setDisplayMode(_ mode: MenuBarDisplayMode) {
    PermanentStorage.menuBarDisplayMode = mode
    applyDisplayMode(mode)
  }

  private func applyDisplayMode(_ mode: MenuBarDisplayMode) {
    guard let button = item.button else { return }
    let image = NSImage(named: "StatusItemIcon")
      ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Kawa")
    image?.isTemplate = true
    if let image { image.size = NSSize(width: 16, height: 16) }
    button.image = mode == .text ? nil : image
    button.title = mode == .icon ? "" : "Kawa"
    button.imagePosition = switch mode {
    case .text: .noImage
    case .icon: .imageOnly
    case .textAndIcon: .imageLeading
    }
    item.isVisible = true
  }

  private func showContextMenu() {
    let menu = NSMenu()

    let showMenu = NSMenu()
    for mode in MenuBarDisplayMode.allCases {
      let item = NSMenuItem(title: mode.title, action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
      item.target = self
      item.representedObject = mode.rawValue
      item.state = PermanentStorage.menuBarDisplayMode == mode ? .on : .off
      showMenu.addItem(item)
    }
    let showItem = NSMenuItem(title: "Show", action: nil, keyEquivalent: "")
    showItem.submenu = showMenu
    menu.addItem(showItem)

    menu.addItem(.separator())

    let settings = NSMenuItem(title: "Show Settings…", action: #selector(showSettings), keyEquivalent: "")
    settings.target = self
    menu.addItem(settings)

    let open = NSMenuItem(title: "Open Kawa", action: #selector(openKawa), keyEquivalent: "")
    open.target = self
    menu.addItem(open)
    menu.addItem(.separator())

    let quit = NSMenuItem(title: "Quit", action: #selector(quitKawa), keyEquivalent: "")
    quit.target = self
    menu.addItem(quit)

    if let button = item.button {
      menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }
  }

  @objc private func selectDisplayMode(_ sender: NSMenuItem) {
    guard let rawValue = sender.representedObject as? String,
          let mode = MenuBarDisplayMode(rawValue: rawValue) else { return }
    setDisplayMode(mode)
  }

  @objc private func showSettings() {
    openPreferences?()
  }

  @objc private func openKawa() {
    (NSApp.delegate as? AppDelegate)?.openKawa()
  }

  @objc private func quitKawa() {
    NSApp.terminate(nil)
  }
}
