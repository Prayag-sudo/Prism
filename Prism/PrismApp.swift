//
//  testingApp.swift
//  testing
//
//  Created by Prayag Chitgupkar on 6/11/25.
//

import SwiftUI
import AppKit
import Foundation

@main
struct testingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
            
                .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
                .containerBackground(.ultraThinMaterial, for: .window)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
