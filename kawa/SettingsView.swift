import AppKit
import KeyboardShortcuts
import ServiceManagement
import SwiftUI

@MainActor
struct SettingsView: View {
  @State private var inputSources: [InputSource] = []
  @State private var notificationsEnabled = PermanentStorage.showsNotification
  @State private var notificationMessage: String?
  @State private var hidesDockIcon = PermanentStorage.hidesDockIcon
  @State private var launchesAtLogin = false
  @State private var loginItemRequiresApproval = false
  @State private var loginItemMessage: String?

  var body: some View {
    TabView {
      shortcutsTab
        .tabItem { Label("Shortcuts", systemImage: "keyboard") }

      generalTab
        .tabItem { Label("System Settings", systemImage: "gearshape") }
    }
    .frame(minWidth: 560, minHeight: 400)
    .onAppear(perform: reloadInputSources)
    .onChange(of: notificationsEnabled) { _, enabled in
      Task { await updateNotificationPreference(enabled) }
    }
  }

  private var shortcutsTab: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Assign a global shortcut to each keyboard input source.")
        .foregroundStyle(.secondary)

      if inputSources.isEmpty {
        ContentUnavailableView(
          "No Keyboard Input Sources",
          systemImage: "keyboard",
          description: Text("Add a keyboard input source in System Settings to configure shortcuts.")
        )
      } else {
        List(inputSources) { source in
          HStack(spacing: 12) {
            Group {
              if let icon = source.icon {
                Image(nsImage: icon).resizable().scaledToFit()
              } else {
                Image(systemName: "keyboard")
              }
            }
            .frame(width: 24, height: 24)

            Text(source.name)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)

            KeyboardShortcuts.Recorder("Shortcut", name: source.shortcutName)
              .frame(width: 190, alignment: .trailing)
          }
          .padding(.vertical, 3)
        }
        .listStyle(.inset)
      }
    }
    .padding(20)
  }

  private var generalTab: some View {
    Form {
      Section("Preferences") {
        Toggle(
          isOn: Binding(
            get: { hidesDockIcon },
            set: { hidden in
              hidesDockIcon = hidden
              PermanentStorage.hidesDockIcon = hidden
              (NSApp.delegate as? AppDelegate)?.setDockIconHidden(hidden)
            }
          )
        ) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Hide Dock Icon")
            Text("Hide the dock icon when all windows are closed.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Toggle(
          "Launch Kawa at login",
          isOn: Binding(
            get: { launchesAtLogin },
            set: { enabled in
              launchesAtLogin = enabled
              loginItemMessage = nil
              updateLoginItem(enabled)
            }
          )
        )
        Toggle("Show a notification when the input source changes", isOn: $notificationsEnabled)
        if let notificationMessage {
          Text(notificationMessage)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        if let loginItemMessage {
          VStack(alignment: .leading, spacing: 6) {
            Text(loginItemMessage)
              .font(.callout)
              .foregroundStyle(.secondary)
            if loginItemRequiresApproval {
              Button("Open Login Items Settings") {
                SMAppService.openSystemSettingsLoginItems()
              }
            }
          }
        }
      }

      Section {
        Button("Quit Kawa") { NSApp.terminate(nil) }
      }
    }
    .formStyle(.grouped)
    .padding(20)
    .onAppear(perform: refreshLoginItemStatus)
  }

  private func reloadInputSources() {
    ShortcutManager.shared.refresh()
    inputSources = InputSource.sources
  }

  private func updateNotificationPreference(_ enabled: Bool) async {
    guard enabled else {
      PermanentStorage.showsNotification = false
      notificationMessage = nil
      return
    }

    if await NotificationService.shared.requestAuthorization() {
      PermanentStorage.showsNotification = true
      notificationMessage = nil
    } else {
      PermanentStorage.showsNotification = false
      notificationsEnabled = false
      notificationMessage = "Allow notifications for Kawa in System Settings to use this option."
    }
  }

  private func refreshLoginItemStatus() {
    Task.detached(priority: .utility) {
      let status = SMAppService.mainApp.status
      await MainActor.run {
        applyLoginItemStatus(status)
      }
    }
  }

  private func updateLoginItem(_ enabled: Bool) {
    Task.detached(priority: .userInitiated) {
      do {
        if enabled {
          try SMAppService.mainApp.register()
        } else {
          try await SMAppService.mainApp.unregister()
        }
        let status = SMAppService.mainApp.status
        await MainActor.run {
          applyLoginItemStatus(status)
        }
      } catch {
        let status = SMAppService.mainApp.status
        await MainActor.run {
          applyLoginItemStatus(status)
          loginItemMessage = "Could not update the login item: \(error.localizedDescription)"
        }
      }
    }
  }

  private func applyLoginItemStatus(_ status: SMAppService.Status) {
    launchesAtLogin = status == .enabled || status == .requiresApproval
    loginItemRequiresApproval = status == .requiresApproval
    loginItemMessage = status == .requiresApproval
      ? "Kawa is registered. Approve it in System Settings → General → Login Items."
      : nil
  }
}
