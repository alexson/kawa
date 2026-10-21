import Foundation

enum MenuBarDisplayMode: String, CaseIterable {
  case text
  case icon
  case textAndIcon

  var title: String {
    switch self {
    case .text: "Text"
    case .icon: "Icon"
    case .textAndIcon: "Text + Icon"
    }
  }
}

enum PermanentStorage {
  private enum Key {
    static let showsNotification = "show-notification"
    static let launchedForTheFirstTime = "launched-for-the-first-time"
    static let hidesDockIcon = "hide-dock-icon"
    static let menuBarDisplayMode = "menu-bar-display-mode"
  }

  static var showsNotification: Bool {
    get { UserDefaults.standard.object(forKey: Key.showsNotification) as? Bool ?? false }
    set { UserDefaults.standard.set(newValue, forKey: Key.showsNotification) }
  }

  static var launchedForTheFirstTime: Bool {
    get { UserDefaults.standard.object(forKey: Key.launchedForTheFirstTime) as? Bool ?? true }
    set { UserDefaults.standard.set(newValue, forKey: Key.launchedForTheFirstTime) }
  }

  static var hidesDockIcon: Bool {
    get { UserDefaults.standard.bool(forKey: Key.hidesDockIcon) }
    set { UserDefaults.standard.set(newValue, forKey: Key.hidesDockIcon) }
  }

  static var menuBarDisplayMode: MenuBarDisplayMode {
    get {
      guard let rawValue = UserDefaults.standard.string(forKey: Key.menuBarDisplayMode),
            let mode = MenuBarDisplayMode(rawValue: rawValue) else { return .textAndIcon }
      return mode
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.menuBarDisplayMode) }
  }
}
