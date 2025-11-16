//
//  AppDelegate.swift
//  Prism
//
//  Created by Prayag Chitgupkar on 6/14/25.
//
import SwiftUI
import AppKit
import Carbon
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private let animationDuration: TimeInterval = 0.25
    private var statusItem: NSStatusItem?
    private var hotKey: HotKey?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupHotKey()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupMainWindow()
            self.showFullScreenWindow()
        }

        setupStatusMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEscape),
            name: .prismEscapePressed,
            object: nil
        )
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        print("App did become active")
        
        setupMainWindow()
        animateShow()
        NotificationCenter.default.post(name: .prismTriggerStartupAnimation, object: nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        print("App did resign active")
        animateHide()
        NotificationCenter.default.post(name: .prismTriggerStartupAnimation, object: nil)
        NotificationCenter.default.post(name: .resetPrismSession, object: nil)
    }

    @objc func applicationDidLaunch(_ notification: Notification) {
        if NSApp.isActive {
            animateHide()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Window Setup

    private func setupMainWindow() {
        guard let window = NSApplication.shared.windows.first,
              let screen = NSScreen.main else { return }

        // ✅ Use the full screen frame
        var frame = screen.visibleFrame

        // ⬆️ Shift the frame upward so it fills space under menu bar
        frame.origin.y = 0
        frame.size.height = screen.frame.height

        window.setFrame(frame, display: true)

        // ✅ Use immersive style
        window.styleMask = [.borderless, .fullSizeContentView]

        // ✅ Behavior: appear in all spaces, no fullscreen takeover
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]

        window.level = .floating
        window.styleMask = [.borderless, .fullSizeContentView]

        // ✅ Normal level so Dock stays above
        window.level = .normal

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear

        // ✅ Hide traffic light buttons
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func showFullScreenWindow() {
        guard let window = NSApplication.shared.windows.first else { return }

        window.setIsVisible(true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Animations

    public func animateHide() {
        guard let window = NSApplication.shared.windows.first else {
            NSApp.hide(nil)
            return
        }
        print("hiding app")
        window.animator().alphaValue = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            NSApp.hide(nil)
            window.alphaValue = 1.0
        }
    }
    
    @objc private func handleEscape() {
        animateHide()
    }

    private func animateShow() {
        guard let window = NSApplication.shared.windows.first else {
            NSApp.unhide(nil)
            return
        }

        NSApp.unhide(nil)

        // 🔁 Restore transparency settings — REQUIRED after another window appears
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        window.alphaValue = 0.0
        window.animator().alphaValue = 1.0
        NotificationCenter.default.post(name: .prismBecameActive, object: nil)
        
    }
    

    // MARK: - Status Bar Menu

    private func setupStatusMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Prism", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: "Prism")
        statusItem?.menu = menu
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func setupHotKey() {
        // Example: Command + Shift + P
        hotKey = HotKey(key: .l, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = {
            self.toggleAppVisibility()
        }
    }

    private func toggleAppVisibility() {
        if NSApp.isActive {
            animateHide()
        } else {
            animateShow()
        }
    }
    
    
    
    @objc private func openSettings() {
        // If it's already open, bring it to front
        if let settingsWindow = self.settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Prism Settings"
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = true // 💡 This is crucial
        window.level = .floating           // So it appears above other windows

        // When window closes, deallocate it
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.settingsWindow = nil
        }

        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let mainWindow = NSApplication.shared.windows.first {
                mainWindow.isOpaque = false
                mainWindow.backgroundColor = .clear
                mainWindow.titlebarAppearsTransparent = true
                mainWindow.titleVisibility = .hidden
            }
    }
    
    
    
}
// MARK: - NSWindowDelegate for Settings Window Cleanup
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow,
           closingWindow == settingsWindow {
            settingsWindow = nil
        }
    }
}
