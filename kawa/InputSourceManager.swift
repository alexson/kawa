import AppKit
import Carbon
import KeyboardShortcuts

@MainActor
struct InputSource: Identifiable, Equatable {
  let tisInputSource: TISInputSource
  let icon: NSImage?

  nonisolated let id: String
  var name: String { tisInputSource.name }
  var shortcutName: KeyboardShortcuts.Name {
    KeyboardShortcuts.Name("kawa-" + id.replacingOccurrences(of: ".", with: "-"))
  }

  init(tisInputSource: TISInputSource) {
    self.tisInputSource = tisInputSource
    id = tisInputSource.id

    var resolvedIcon: NSImage?
    if let imageURL = tisInputSource.iconImageURL {
      for url in [imageURL.retinaImageURL, imageURL.tiffImageURL, imageURL] {
        if let image = NSImage(contentsOf: url) {
          resolvedIcon = image
          break
        }
      }
    }
    if resolvedIcon == nil, let iconRef = tisInputSource.iconRef {
      resolvedIcon = NSImage(iconRef: iconRef)
    }
    icon = resolvedIcon
  }

  func select() -> Bool {
    TISSelectInputSource(tisInputSource) == noErr
  }

  nonisolated static func == (lhs: InputSource, rhs: InputSource) -> Bool {
    lhs.id == rhs.id
  }

  static var sources: [InputSource] {
    let list = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
    return (list as? [TISInputSource] ?? [])
      .filter { $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable }
      .map(InputSource.init(tisInputSource:))
  }
}

@MainActor
final class ShortcutManager {
  static let shared = ShortcutManager()
  private var registeredSourceIDs = Set<String>()

  private init() {
    refresh()
  }

  func refresh() {
    migrateLegacyShortcuts()
    for source in InputSource.sources where registeredSourceIDs.insert(source.id).inserted {
      let inputSourceID = source.id
      KeyboardShortcuts.onKeyUp(for: source.shortcutName) {
        guard let currentSource = InputSource.sources.first(where: { $0.id == inputSourceID }) else { return }
        guard currentSource.select() else { return }
        if PermanentStorage.showsNotification {
          NotificationService.shared.showInputSource(currentSource)
        }
      }
    }
  }

  private func migrateLegacyShortcuts() {
    let defaults = UserDefaults.standard
    for source in InputSource.sources {
      let legacyKey = source.id.replacingOccurrences(of: ".", with: "-")
      let shortcutKey = "KeyboardShortcuts_\(source.shortcutName.rawValue)"
      guard
        let archivedValue = defaults.object(forKey: legacyKey),
        defaults.object(forKey: shortcutKey) == nil,
        let shortcut = Self.decodeLegacyShortcut(archivedValue)
      else { continue }

      source.shortcutName.shortcut = shortcut
      if defaults.object(forKey: shortcutKey) != nil {
        defaults.removeObject(forKey: legacyKey)
      }
    }
  }

  private static func decodeLegacyShortcut(_ value: Any) -> KeyboardShortcuts.Shortcut? {
    guard let data = value as? Data else { return nil }
    NSKeyedUnarchiver.setClass(LegacyShortcutArchive.self, forClassName: "MASShortcut")
    do {
      let archive = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: LegacyShortcutArchive.self,
        from: data
      )
      guard let archive, archive.keyCode >= 0 else { return nil }
      let cocoaModifiers = NSEvent.ModifierFlags(rawValue: UInt(archive.modifierFlags))
      var carbonModifiers = 0
      if cocoaModifiers.contains(.command) { carbonModifiers |= Int(cmdKey) }
      if cocoaModifiers.contains(.shift) { carbonModifiers |= Int(shiftKey) }
      if cocoaModifiers.contains(.option) { carbonModifiers |= Int(optionKey) }
      if cocoaModifiers.contains(.control) { carbonModifiers |= Int(controlKey) }
      return KeyboardShortcuts.Shortcut(
        carbonKeyCode: archive.keyCode,
        carbonModifiers: carbonModifiers
      )
    } catch {
      return nil
    }
  }
}

@objc(LegacyShortcutArchive)
final class LegacyShortcutArchive: NSObject, NSSecureCoding {
  static var supportsSecureCoding: Bool { true }
  let keyCode: Int
  let modifierFlags: Int

  required init?(coder: NSCoder) {
    keyCode = coder.decodeInteger(forKey: "KeyCode")
    modifierFlags = coder.decodeInteger(forKey: "ModifierFlags")
    super.init()
  }

  func encode(with coder: NSCoder) {}
}

private extension URL {
  var retinaImageURL: URL {
    let filename = deletingPathExtension().lastPathComponent
    return deletingLastPathComponent()
      .appendingPathComponent(filename + "@2x")
      .appendingPathExtension(pathExtension)
  }

  var tiffImageURL: URL {
    deletingPathExtension().appendingPathExtension("tiff")
  }
}
