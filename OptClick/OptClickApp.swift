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
            
            settingsWindow?.level = .normal
            settingsWindow?.collectionBehavior = [.participatesInCycle]
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(settingsWindowWillClose),
                name: NSWindow.willCloseNotification,
                object: settingsWindow
            )
        }
        
        NSApp.setActivationPolicy(.regular)
        
        // Show the window and bring app to front
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func settingsWindowWillClose(_ notification: Notification) {
        let otherVisibleWindows = NSApp.windows.filter {
            $0.isVisible && $0 != settingsWindow
        }
        if otherVisibleWindows.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
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
        
        updateStatusBarIcon()
    }
    
    @objc private func handleHotkeyTriggered() {
        inputManager.isEnabled.toggle()
        updateStatusBarIcon()
    }
    
    // Menu bar icon
    private var cachedEnabledIcon: NSImage?
    private var cachedDisabledIcon: NSImage?

    func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }

        let icon: NSImage
        if inputManager.isEnabled {
            icon = cachedEnabledIcon ?? makeOptionIcon()
            cachedEnabledIcon = icon
        } else {
            icon = cachedDisabledIcon ?? makeOptionWithSlashIcon()
            cachedDisabledIcon = icon
        }

        button.image = icon
    }

    private func makeOptionIcon() -> NSImage {
        let size = NSSize(width: 15, height: 15)
        let image = NSImage(systemSymbolName: "option", accessibilityDescription: "Option")!
        let resized = resizeImage(image, to: size)
        resized.isTemplate = true
        return resized
    }

    private func makeOptionWithSlashIcon() -> NSImage {
        let size = NSSize(width: 15, height: 15)

        let combinedImage = NSImage(size: size)
        combinedImage.lockFocus()

        // Draw option
        if let optionImage = NSImage(systemSymbolName: "option", accessibilityDescription: nil) {
            let resizedOption = resizeImage(optionImage, to: size)
            resizedOption.draw(in: NSRect(origin: .zero, size: size))
        }

        // Draw slash
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 2, y: 1))
        path.line(to: NSPoint(x: size.width-2, y: size.height-1))
        path.lineWidth = 2
        path.lineCapStyle = .round
        path.stroke()

        combinedImage.unlockFocus()
        combinedImage.isTemplate = true
        return combinedImage
    }

    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let scaled = NSImage(size: size)
        scaled.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        scaled.unlockFocus()
        return scaled
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
