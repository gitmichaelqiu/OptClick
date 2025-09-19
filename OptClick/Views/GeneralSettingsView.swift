import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var inputManager: InputManager
    @State private var autoCheckForUpdates = UpdateManager.isAutoCheckEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(NSLocalizedString("Settings.General.Option.Enable", comment: "Enable option to right click"), isOn: $inputManager.isEnabled)
            
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
