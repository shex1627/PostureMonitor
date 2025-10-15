//
//  PostureMonitorApp.swift
//  PostureMonitor
//
//  Created by Shicheng Huang on 10/14/25.
//

import SwiftUI
import UserNotifications

// Notification delegate to show alerts even when app is in foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct PostureMonitorApp: App {
    // Keep delegate alive
    static let notificationDelegate = NotificationDelegate()

    init() {
        // Set up notification delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
