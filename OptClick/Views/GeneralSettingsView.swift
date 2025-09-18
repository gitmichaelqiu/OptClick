import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var inputManager: InputManager

    var body: some View {
        Form {
            Toggle("Enable Option → Right Click", isOn: $inputManager.isEnabled)
            Spacer()
        }
        .padding()
    }
}
