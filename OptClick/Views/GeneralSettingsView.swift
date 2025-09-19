import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var inputManager: InputManager
    @State private var autoCheckForUpdates = UpdateManager.isAutoCheckEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Option → Right Click", isOn: $inputManager.isEnabled)
            
            Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
                .onChange(of: autoCheckForUpdates) {
                    UpdateManager.isAutoCheckEnabled = autoCheckForUpdates
                }
            
            Button("Check for Updates") {
                UpdateManager.shared.checkForUpdate(from: nil)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
