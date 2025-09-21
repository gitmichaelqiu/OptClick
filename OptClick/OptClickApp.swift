import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    @StateObject private var inputManager = InputManager()
    @StateObject private var hotkeyManager = HotkeyManager()
    
    @objc func showSettings() {
        guard let statusBarButton = statusItem?.button else { return }
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .maxY)
    }
    
    func addMenuItems() {
        statusItem?.menu?.removeAllItems()
        statusItem?.menu?.addItem(withTitle: "Settings...", action: #selector(showSettings), keyEquivalent: "")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "OptClick"
        
        statusItem?.menu = NSMenu()
        statusItem?.menu?.delegate = self
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        addMenuItems()
    }
}

@main
struct OptClickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
//        WindowGroup {
//            SettingsView()
//                .environmentObject(inputManager)
//                .environmentObject(hotkeyManager)
//                .frame(width: 450, height: 450)
//                .onAppear {
//                    NotificationCenter.default.addObserver(
//                        forName: .hotkeyTriggered,
//                        object: nil,
//                        queue: .main
//                    ) { _ in
//                        inputManager.isEnabled.toggle()
//                    }
//                }
//        }
//        .windowResizability(.contentSize)
    }
}
