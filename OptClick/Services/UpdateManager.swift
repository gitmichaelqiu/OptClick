import Foundation
import AppKit

class UpdateManager {
    static let shared = UpdateManager()
    private init() {}

    private let latestReleaseAPI = "https://api.github.com/repos/gitmichaelqiu/OptClick/releases/latest"
    private let latestReleaseURL = "https://github.com/gitmichaelqiu/OptClick/releases/latest"

    // UserDefaults key for auto update check
    static let autoCheckKey = "AutoCheckForUpdate"
    static var isAutoCheckEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoCheckKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoCheckKey) }
    }

    func checkForUpdate(from window: NSWindow?, suppressUpToDateAlert: Bool = false) {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        let url = URL(string: latestReleaseAPI)!
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else {
                if !suppressUpToDateAlert {
                    self.showAlert(
                        NSLocalizedString("Settings.General.Update.Failed.Title", comment: ""),
                        NSLocalizedString("Settings.General.Update.Failed.Msg", comment: ""),
                        window: window
                    )
                }
                return
            }
            let latestVersion = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            if self.isNewerVersion(latestVersion, than: currentVersion) {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Settings.General.Update.Available.Title", comment: "")
                    alert.informativeText = String(format: NSLocalizedString("Settings.General.Update.Available.Msg", comment: ""), latestVersion)
                    alert.addButton(withTitle: NSLocalizedString("Settings.General.Update.Available.Button.Update", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Settings.General.Update.Available.Button.Cancel", comment: ""))
                    alert.alertStyle = .informational
                    if alert.runModal() == .alertFirstButtonReturn {
                        if let releaseURL = URL(string: self.latestReleaseURL) {
                            NSWorkspace.shared.open(releaseURL)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NSApp.terminate(nil)
                        }
                    }
                }
            } else if !suppressUpToDateAlert {
                self.showAlert(
                    NSLocalizedString("Settings.General.Update.UpToDate.Title", comment: ""),
                    String(format: NSLocalizedString("Settings.General.Update.UpToDate.Msg", comment: ""), currentVersion),
                    window: window
                )
            }
        }
        task.resume()
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

    private func showAlert(_ title: String, _ message: String, window: NSWindow?) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            if let window = window {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        }
    }
}
