import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var inputManager: InputManager
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OptClick Settings")
                .font(.largeTitle)
                .bold()

            Toggle(isOn: $inputManager.isEnabled) {
                Text("Enable Option → Right Click")
            }
            .toggleStyle(SwitchToggleStyle())

            Divider()

            VStack(alignment: .leading, spacing: 10) {
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

                Text("Press the hotkey to toggle OptClick on/off")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(width: 420, height: 240)
        .padding()
    }
}
