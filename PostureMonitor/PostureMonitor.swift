import Foundation
import UserNotifications
import UIKit

/// Monitors posture and sends notifications when posture is bad
class PostureMonitor: ObservableObject {
    @Published var currentAngle: Double = 0.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var badPostureCount: Int = 0
    @Published var isMonitoring: Bool = false

    // Configurable settings
    @Published var badPostureThreshold: Double = 30.0 // degrees
    @Published var notificationInterval: TimeInterval = 5.0 // seconds
    @Published var keepScreenOn: Bool = false // prevent screen from auto-locking

    // Bad posture timing
    private var badPostureStartTime: Date?
    private var lastNotificationTime: Date?

    // Session tracking
    private var sessionStartTime: Date?
    private var timer: Timer?

    func startMonitoring() {
        sessionStartTime = Date()
        badPostureCount = 0
        isMonitoring = true
        badPostureStartTime = nil
        lastNotificationTime = nil

        // Request notification permissions
        requestNotificationPermission()

        // Control screen idle timer
        updateScreenIdleTimer()

        // Start timer for session duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }

        print("Started posture monitoring")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        badPostureStartTime = nil
        lastNotificationTime = nil

        // Restore screen idle timer to normal
        UIApplication.shared.isIdleTimerDisabled = false

        print("Stopped posture monitoring")
    }

    func updateAngle(_ angle: Double) {
        currentAngle = angle
        checkPosture(angle)
    }

    private func checkPosture(_ angle: Double) {
        guard isMonitoring else { return }

        let now = Date()
        let isBadPosture = angle > badPostureThreshold

        if isBadPosture {
            // Start timer if not already started
            if badPostureStartTime == nil {
                badPostureStartTime = now
                print("Bad posture detected (\(Int(angle))°)")
            }

            // Check if 15 seconds have passed
            if let startTime = badPostureStartTime {
                let duration = now.timeIntervalSince(startTime)

                // Send notification every 15 seconds
                if duration >= notificationInterval {
                    if shouldSendNotification(now: now) {
                        sendNotification(angle: angle)
                        lastNotificationTime = now
                        badPostureCount += 1
                    }
                }
            }
        } else {
            // Good posture - reset
            if badPostureStartTime != nil {
                print("Good posture restored")
                badPostureStartTime = nil
            }
        }
    }

    private func shouldSendNotification(now: Date) -> Bool {
        // First notification, or 15 seconds since last one
        guard let lastTime = lastNotificationTime else { return true }
        return now.timeIntervalSince(lastTime) >= notificationInterval
    }

    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(startTime)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendNotification(angle: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Posture Alert!"
        content.body = "Your head is tilted \(Int(angle))°. Straighten up!"

        // Use critical alert sound for more impact (requires special permission)
        // For now, use defaultCritical which is louder than default
        if #available(iOS 15.0, *) {
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
        } else {
            // Use default ringtone sound which is louder
            content.sound = .default
        }

        // Add badge to make it more noticeable
        content.badge = NSNumber(value: badPostureCount)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            } else {
                print("Sent posture alert notification")
            }
        }
    }

    func updateScreenIdleTimer() {
        // Only keep screen on if monitoring is active AND setting is enabled
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = self.isMonitoring && self.keepScreenOn
            if self.keepScreenOn && self.isMonitoring {
                print("Screen will stay on during monitoring")
            }
        }
    }
}
