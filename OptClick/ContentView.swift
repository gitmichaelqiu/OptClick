import SwiftUI

struct ContentView: View {
    @EnvironmentObject var inputManager: InputManager

    var body: some View {
        VStack(spacing: 20) {
            Text("OptClick")
                .font(.largeTitle)
                .bold()

            Toggle(isOn: $inputManager.isEnabled) {
                Text("Enable Option → Right Click")
            }
            .toggleStyle(SwitchToggleStyle())
            .padding()

            if inputManager.isEnabled {
                Text("Enabled: Press or hold Option (⌥) to simulate right click.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}
