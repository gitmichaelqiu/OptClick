import SwiftUI

@main
struct OptClickApp: App {
    @StateObject private var inputManager = InputManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(inputManager)
        }
    }
}
