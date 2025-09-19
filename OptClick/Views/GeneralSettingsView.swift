import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var inputManager: InputManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Option → Right Click", isOn: $inputManager.isEnabled)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
