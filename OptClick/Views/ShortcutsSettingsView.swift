import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Toggle Hotkey")
                .font(.headline)

            HStack {
                Text(NSLocalizedString("Settings.Shortcuts.Hotkey.Current", comment: "Current") + hotkeyManager.shortcutDescription)
                    .font(.body)

                Spacer()

                Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Change", comment: "Change")) {
                    hotkeyManager.startListeningForNewShortcut()
                }

                Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Reset", comment: "Reset")) {
                    hotkeyManager.resetToDefault()
                }
            }

            Text(NSLocalizedString("Settings.Shortcuts.Hotkey.Hint", comment: "Press this hotkey to enable or disable OptClick."))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
