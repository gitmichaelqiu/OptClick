import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection("Settings.Shortcuts.Hotkey") {
                    // Row: label + current shortcut
                    SettingsRow("Settings.Shortcuts.Hotkey.Toggle") {
                        Text(hotkeyManager.shortcutDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    Divider()

                    // Row: buttons aligned right
                    HStack {
                        Spacer()
                        Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Change", comment: "Change")) {
                            hotkeyManager.startListeningForNewShortcut()
                        }
                        Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Reset", comment: "Reset")) {
                            hotkeyManager.resetToDefault()
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
