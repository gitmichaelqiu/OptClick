import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Toggle Hotkey")
                .font(.headline)

            HStack {
                Text("Current: \(hotkeyManager.shortcutDescription)")
                    .font(.body)

                Spacer()

                Button("Change…") {
                    hotkeyManager.startListeningForNewShortcut()
                }

                Button("Reset") {
                    hotkeyManager.resetToDefault()
                }
            }

            Text("Press this hotkey to enable or disable OptClick.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
