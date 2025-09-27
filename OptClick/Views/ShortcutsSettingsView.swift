import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection("Settings.Shortcuts.General") {
                    // Row: label + current shortcut
                    SettingsRow("Settings.Shortcuts.Hotkey") {
                        Text(hotkeyManager.shortcutDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(minHeight: 36) // unify row height

                    Divider()

                    // Row: buttons aligned right
                    SettingsRow("") {
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Change", comment: "Change")) {
                                hotkeyManager.startListeningForNewShortcut()
                            }
                            Button(NSLocalizedString("Settings.Shortcuts.Hotkey.Reset", comment: "Reset")) {
                                hotkeyManager.resetToDefault()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(minHeight: 36) // unify row height
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
