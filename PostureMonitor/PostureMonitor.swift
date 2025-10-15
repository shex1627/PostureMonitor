import Foundation
import UserNotifications

/// Monitors posture and sends notifications when posture is bad
class PostureMonitor: ObservableObject {
    @Published var currentAngle: Double = 0.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var badPostureCount: Int = 0
    @Published var isMonitoring: Bool = false

    private let badPostureThreshold: Double = 30.0 // degrees
    private let checkInterval: TimeInterval = 2.0 // seconds

    private var sessionStartTime: Date?
    private var timer: Timer?
    private var lastNotificationTime: Date?
    private let notificationCooldown: TimeInterval = 30.0 // Don't spam notifications

    func startMonitoring() {
        sessionStartTime = Date()
        badPostureCount = 0
        isMonitoring = true

        // Request notification permissions
        requestNotificationPermission()

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
        print("Stopped posture monitoring")
    }

    func updateAngle(_ angle: Double) {
        currentAngle = angle
        checkPosture(angle)
    }

    private func checkPosture(_ angle: Double) {
        guard isMonitoring else { return }

        if angle > badPostureThreshold {
            // Bad posture detected
            sendNotificationIfNeeded()
            badPostureCount += 1
        }
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

    private func sendNotificationIfNeeded() {
        let now = Date()

        // Check cooldown
        if let lastTime = lastNotificationTime,
           now.timeIntervalSince(lastTime) < notificationCooldown {
            return
        }

        lastNotificationTime = now
        sendNotification()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Posture Alert!"
        content.body = "Your head is tilted \(Int(currentAngle))°. Straighten up!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}
