import SwiftUI

@main
struct OptClickApp: App {
    @StateObject private var inputManager = InputManager()
    @StateObject private var hotkeyManager = HotkeyManager()

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(inputManager)
                .environmentObject(hotkeyManager)
                .onAppear {
                    NotificationCenter.default.addObserver(
                        forName: .hotkeyTriggered,
                        object: nil,
                        queue: .main
                    ) { _ in
                        inputManager.isEnabled.toggle()
                    }
                }
        }
    }
}
