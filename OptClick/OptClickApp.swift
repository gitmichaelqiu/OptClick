import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    let inputManager = InputManager()
    let hotkeyManager = HotkeyManager()
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func openSettingsWindow() {
        if settingsWindow == nil {
            // Create settingsView
            let settingsView = SettingsView(inputManager: inputManager)
                .environmentObject(hotkeyManager)
            
            let windowSize = NSSize(width: 450, height: 400)
            
            // Create a new window
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            settingsWindow?.center()
            settingsWindow?.setFrameAutosaveName("Settings")
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.isReleasedWhenClosed = false
            
            settingsWindow?.minSize = windowSize
            settingsWindow?.maxSize = windowSize
        }
        
        // Show the window and bring app to front
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupMenuItems() {
        let menu = NSMenu()
        
        // Settings menu item
        let settingsItem = NSMenuItem(
            title: NSLocalizedString("Settings...", comment: "Settings menu item"),
            action: #selector(openSettingsWindow),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Seaparator
        menu.addItem(NSMenuItem.separator())
        
        // Quit menu item
        let quitItem = NSMenuItem(
            title: NSLocalizedString("Quit OptClick", comment: "Quit menu item"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "OptClick")
        }
        
        setupMenuItems()
        
        // Setup hotkey observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeyTriggered),
            name: .hotkeyTriggered,
            object: nil
        )
    }
    
    @objc private func handleHotkeyTriggered() {
        inputManager.isEnabled.toggle()
    }
    
}

@main
struct OptClickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
