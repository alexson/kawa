import AppKit
import UserNotifications

@MainActor
final class NotificationService {
  static let shared = NotificationService()
  private let notificationID = "kawa-input-source-change"

  func requestAuthorization() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
      let settings = await center.notificationSettings()
      if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
        return true
      }
      return try await center.requestAuthorization(options: [.alert])
    } catch {
      return false
    }
  }

  func showInputSource(_ source: InputSource) {
    Task {
      guard await requestAuthorization() else { return }
      let content = UNMutableNotificationContent()
      content.title = "Kawa"
      content.body = source.name
      let attachmentURL = Self.attachmentURL(for: source.icon)
      if let attachmentURL,
         let attachment = try? UNNotificationAttachment(identifier: "input-source-icon", url: attachmentURL) {
        content.attachments = [attachment]
      }

      let center = UNUserNotificationCenter.current()
      center.removeDeliveredNotifications(withIdentifiers: [notificationID])
      center.removePendingNotificationRequests(withIdentifiers: [notificationID])
      try? await center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: nil))
      if let attachmentURL { try? FileManager.default.removeItem(at: attachmentURL) }
    }
  }

  private static func attachmentURL(for image: NSImage?) -> URL? {
    guard
      let image,
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
    else { return nil }

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("kawa-input-source-\(UUID().uuidString).png")
    do {
      try png.write(to: url, options: .atomic)
      return url
    } catch {
      return nil
    }
  }
}
