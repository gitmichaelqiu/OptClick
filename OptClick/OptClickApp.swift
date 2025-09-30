import SwiftUI
import Combine
import AppKit

let defaultSettingsWindowWidth = 450
let defaultSettingsWindowHeight = 450

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    private var inputManagerCancellable: AnyCancellable?
    
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
            
            let windowSize = NSSize(width: defaultSettingsWindowWidth, height: defaultSettingsWindowHeight)
            
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
//        let otherVisibleWindows = NSApp.windows.filter {
//            $0.isVisible && $0 != settingsWindow
//        }
//        if otherVisibleWindows.isEmpty {
//            print("HI")
        NSApp.setActivationPolicy(.accessory)
//        }
    }
    
    func setupMenuItems() {
        let menu = NSMenu()

        // --- Toggle OptClick ---
        let toggleTitle = inputManager.isEnabled
            ? NSLocalizedString("Menu.Toggle.Disable", comment: "Disable OptClick")
            : NSLocalizedString("Menu.Toggle.Enable", comment: "Enable OptClick")
        let toggleItem = NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleOptClick),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        // --- Status Reason (non-clickable) ---
        let statusReason = autoToggleStatusReason()
        let statusReasonItem = NSMenuItem(title: statusReason, action: nil, keyEquivalent: "")
        statusReasonItem.isEnabled = false
        menu.addItem(statusReasonItem)

        // Separator
        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: NSLocalizedString("Menu.Settings", comment: "Settings"),
            action: #selector(openSettingsWindow),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Separator
        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: NSLocalizedString("Menu.Quit", comment: "Quit"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }
    
    @objc func toggleOptClick() {
        inputManager.isEnabled.toggle()
        setupMenuItems()
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
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostAppDidChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        inputManagerCancellable = inputManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusBarIcon()
                    self?.setupMenuItems()
                }
            }
        
        updateStatusBarIcon()
    }
    
    @objc private func handleHotkeyTriggered() {
        inputManager.isEnabled.toggle()
//        updateStatusBarIcon()
    }
    
    @objc private func frontmostAppDidChange() {
        // Only update menu if AutoToggle is active
        let autoToggleAppBundleIds = UserDefaults.standard.stringArray(forKey: "AutoToggleAppBundleIds") ?? []
        if !autoToggleAppBundleIds.isEmpty {
            DispatchQueue.main.async {
                self.setupMenuItems()
            }
        }
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
    
    deinit {
        inputManagerCancellable?.cancel()
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    private let iconSize = NSSize(width: 15, height: 15)

    private func makeOptionIcon() -> NSImage {
        let image = NSImage(systemSymbolName: "option", accessibilityDescription: "Option")!
        let resized = resizeImage(image, to: iconSize)
        resized.isTemplate = true
        return resized
    }

    private func makeOptionWithSlashIcon() -> NSImage {
        let padding: CGFloat = 3

        let combinedImage = NSImage(size: iconSize)
        combinedImage.lockFocus()

        // Draw option
        if let optionImage = NSImage(systemSymbolName: "option", accessibilityDescription: "Option") {
            let resizedOption = resizeImage(optionImage, to: iconSize)
            resizedOption.draw(in: NSRect(origin: .zero, size: iconSize))
        }
        
        // Erase path
        let erasePath = NSBezierPath()
        erasePath.move(to: NSPoint(x: padding, y: padding))
        erasePath.line(to: NSPoint(x: iconSize.width-padding, y: iconSize.height-padding))
        erasePath.lineWidth = 4.0
        erasePath.lineCapStyle = .round
        
        if let context = NSGraphicsContext.current {
            let originalOp = context.compositingOperation
            context.compositingOperation = .destinationOut

            NSColor.white.set()
            erasePath.stroke()

            context.compositingOperation = originalOp
        }
        
        // Draw slash
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 2, y: 1))
        path.line(to: NSPoint(x: iconSize.width-2, y: iconSize.height-1))
        path.lineWidth = 1.5
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
    
    private func autoToggleStatusReason() -> String {
        let inputManager = self.inputManager
        let state = inputManager.isEnabled
        let stateStr = state ? NSLocalizedString("Menu.Reason.StateStr.Enabled", comment: "Enabled") : NSLocalizedString("Menu.Reason.StateStr.Disabled", comment: "Disabled")
        
        // If no auto toggle apps
        let autoToggleAppBundleIds = UserDefaults.standard.stringArray(forKey: "AutoToggleAppBundleIds") ?? []
        if autoToggleAppBundleIds.isEmpty {
            return String(format: NSLocalizedString("Menu.Reason.Manual", comment: "Manual setting"), stateStr)
        }
        
        // Get frontmost
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontmostApp.bundleIdentifier else {
            return String(format: NSLocalizedString("Menu.Reason.Unknown", comment: ""), stateStr)
        }
        
        let appName = frontmostApp.localizedName ?? bundleId
        
        if autoToggleAppBundleIds.contains(bundleId) {
            if !state {
                return String(format: NSLocalizedString("Menu.Reason.TmpManual", comment: ""), stateStr)
            }
            return String(format: NSLocalizedString("Menu.Reason.IsFrontmost", comment: ""), stateStr, appName)
        } else {
            let behaviorRaw = UserDefaults.standard.string(forKey: "AutoToggleBehavior") ?? "disable"
            let behavior = AutoToggleBehavior(rawValue: behaviorRaw) ?? .disable
            
            switch behavior {
            case .disable:
                if state {
                    return String(format: NSLocalizedString("Menu.Reason.TmpManual", comment: ""), stateStr)
                }
                return String(format: NSLocalizedString("Menu.Reason.NoFrontmost", comment: ""), stateStr)
            case .followLast:
                let lastState = UserDefaults.standard.bool(forKey: InputManager.lastStateKey)
                
                if lastState == state {
                    return String(format: NSLocalizedString("Menu.Reason.LastManual", comment: ""), stateStr)
                }
                return String(format: NSLocalizedString("Menu.Reason.Manual", comment: ""), stateStr)
            }
        }
    }
}

@main
struct OptClickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About OptClick") {
                    // Turn to about page directly because menu bar is only available when settings are opened
                    UserDefaults.standard.set(SettingsTab.about.rawValue, forKey: "selectedSettingsTab")
                }
            }
            CommandGroup(replacing: .appSettings) {
                // Remove default settings
            }
        }
    }
}
