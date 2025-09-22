import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var inputManager: InputManager
    @State private var autoCheckForUpdates = UpdateManager.isAutoCheckEnabled
    @State private var launchAtLogin = LaunchManager.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(NSLocalizedString("Settings.General.Option.Enable", comment: "Enable option to right click"), isOn: $inputManager.isEnabled)
            
            Toggle(NSLocalizedString("Settings.General.Launch", comment: "Launch at login"), isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) {
                    LaunchManager.setEnabled(launchAtLogin)
                }
            
            Toggle(NSLocalizedString("Settings.General.Update.AutoCheck", comment: "Automatically check for updates"), isOn: $autoCheckForUpdates)
                .onChange(of: autoCheckForUpdates) {
                    UpdateManager.isAutoCheckEnabled = autoCheckForUpdates
                }
            
            Button(NSLocalizedString("Settings.General.Update.ManualCheck", comment: "Check for Updates")) {
                UpdateManager.shared.checkForUpdate(from: nil)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
