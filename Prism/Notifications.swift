//
//  Notifications.swift
//  Prism
//
//  Created by Prayag Chitgupkar on 11/12/25.
//
import Foundation
extension Notification.Name {
    static let prismBecameActive = Notification.Name("prismBecameActive")
    static let prismTriggerStartupAnimation = Notification.Name("prismTriggerStartupAnimation")
    static let prismMoveApp = Notification.Name("prismMoveApp")
    static let resetPrismSession = Notification.Name("resetPrismSession")
    static let prismEscapePressed = Notification.Name("prismEscapePressed")
    static let prismResetLayout = Notification.Name("prismResetLayout")
    
}
