import Foundation
import AppKit
import UserNotifications

class UpdateManager {
    static let shared = UpdateManager()
    private init() {}

    let latestReleaseAPI = "https://api.github.com/repos/gitmichaelqiu/OptClick/releases/latest"
    let latestReleaseURL = "https://github.com/gitmichaelqiu/OptClick/releases/latest"

    // UserDefaults key for auto update check
    static let autoCheckKey = "AutoCheckForUpdate"
    static var isAutoCheckEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoCheckKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoCheckKey) }
    }

    @MainActor
    func checkForUpdate(from window: NSWindow?, suppressUpToDateAlert: Bool = false) async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }

        let url = URL(string: latestReleaseAPI.trimmingCharacters(in: .whitespacesAndNewlines))!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else {
                if !suppressUpToDateAlert {
                    await showAlert(
                        NSLocalizedString("Settings.General.Update.Failed.Title", comment: ""),
                        NSLocalizedString("Settings.General.Update.Failed.Msg", comment: ""),
                        in: window
                    )
                }
                return
            }

            let latestVersion = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            if isNewerVersion(latestVersion, than: currentVersion) {
                if suppressUpToDateAlert {
                    self.sendUpdateNotification(latestVersion: latestVersion, currentVersion: currentVersion)
                    return
                }
                
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Settings.General.Update.Available.Title", comment: "")
                alert.informativeText = String(format: NSLocalizedString("Settings.General.Update.Available.Msg", comment: ""), latestVersion)
                alert.addButton(withTitle: NSLocalizedString("Settings.General.Update.Available.Button.Update", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Settings.General.Update.Available.Button.Cancel", comment: ""))
                alert.alertStyle = .informational

                let response = await alert.beginSheetModal(for: window ?? NSApp.mainWindow ?? NSApp.windows.first!)
                if response == .alertFirstButtonReturn {
                    if let releaseURL = URL(string: latestReleaseURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        NSWorkspace.shared.open(releaseURL)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.terminate(nil)
                    }
                }
            } else if !suppressUpToDateAlert {
                await showAlert(
                    NSLocalizedString("Settings.General.Update.UpToDate.Title", comment: ""),
                    String(format: NSLocalizedString("Settings.General.Update.UpToDate.Msg", comment: ""), currentVersion),
                    in: window
                )
            }
        } catch {
            if !suppressUpToDateAlert {
                await showAlert(
                    NSLocalizedString("Settings.General.Update.Failed.Title", comment: ""),
                    NSLocalizedString("Settings.General.Update.Failed.Msg", comment: ""),
                    in: window
                )
            }
        }
    }

    private func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        for (l, c) in zip(latestParts, currentParts) {
            if l > c { return true }
            if l < c { return false }
        }
        return latestParts.count > currentParts.count
    }

    @MainActor
    private func showAlert(_ title: String, _ message: String, in window: NSWindow?) async {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational

        if let window = window {
            _ = await alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    private func sendUpdateNotification(latestVersion: String, currentVersion: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Update Available", comment: "")
        content.body = String(
            format: NSLocalizedString("A new version %@ is available (current: %@). Click to download.", comment: ""),
            latestVersion,
            currentVersion
        )
        content.sound = .default
        content.categoryIdentifier = "updateAvailable"

        let openAction = UNNotificationAction(
            identifier: "openRelease",
            title: NSLocalizedString("Open in Browser", comment: ""),
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "updateAvailable",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        let request = UNNotificationRequest(
            identifier: "UpdateAvailable-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().requestAuthorization { granted, error in
            if granted {
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}
