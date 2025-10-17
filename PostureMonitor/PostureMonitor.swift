import Foundation
import UserNotifications
import UIKit

/// Monitors posture and sends notifications when posture is bad
class PostureMonitor: ObservableObject {
    @Published var currentAngle: Double = 0.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var badPostureCount: Int = 0
    @Published var isMonitoring: Bool = false

    // Free tier limits
    private let freeSessionsPerDay = 3
    private let freeSessionDurationLimit: TimeInterval = 30 * 60 // 30 minutes
    private let freeTierThreshold: Double = 30.0
    private let freeTierInterval: TimeInterval = 15.0

    // Computed property for sessions remaining today
    @Published var sessionsRemainingToday: Int = 0

    // Reference to subscription manager
    private let subscriptionManager = SubscriptionManager.shared

    // Configurable settings with persistence
    @Published var badPostureThreshold: Double {
        didSet {
            // Only save if premium user, otherwise reset to free tier default
            if subscriptionManager.isPremium {
                UserDefaults.standard.set(badPostureThreshold, forKey: "badPostureThreshold")
                print("💾 Saved threshold: \(Int(badPostureThreshold))°")
            } else {
                badPostureThreshold = freeTierThreshold
            }
        }
    }

    @Published var notificationInterval: TimeInterval {
        didSet {
            // Only save if premium user, otherwise reset to free tier default
            if subscriptionManager.isPremium {
                UserDefaults.standard.set(notificationInterval, forKey: "notificationInterval")
                print("💾 Saved notification interval: \(Int(notificationInterval))s")
            } else {
                notificationInterval = freeTierInterval
            }
        }
    }

    @Published var keepScreenOn: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenOn, forKey: "keepScreenOn")
            print("💾 Saved keep screen on: \(keepScreenOn)")
        }
    }

    // Bad posture timing
    private var badPostureStartTime: Date?
    private var lastNotificationTime: Date?

    // Session tracking
    private var sessionStartTime: Date?
    private var timer: Timer?

    init() {
        // Load saved settings or use free tier defaults for non-premium users
        let savedThreshold = UserDefaults.standard.object(forKey: "badPostureThreshold") as? Double ?? freeTierThreshold
        let savedInterval = UserDefaults.standard.object(forKey: "notificationInterval") as? TimeInterval ?? freeTierInterval

        // Set to free tier defaults initially (will be updated based on premium status)
        self.badPostureThreshold = savedThreshold
        self.notificationInterval = savedInterval
        self.keepScreenOn = UserDefaults.standard.bool(forKey: "keepScreenOn")

        print("📱 Loaded settings - Threshold: \(Int(badPostureThreshold))°, Interval: \(Int(notificationInterval))s, Keep Screen On: \(keepScreenOn)")

        // Update sessions remaining
        updateSessionsRemaining()
    }

    // MARK: - Session Limits

    /// Check if user can start a new session
    func canStartSession() -> (canStart: Bool, reason: String?) {
        // Premium users have unlimited sessions
        if subscriptionManager.isPremium {
            return (true, nil)
        }

        // Check daily session limit for free users
        let todaySessions = getTodaySessionCount()
        if todaySessions >= freeSessionsPerDay {
            return (false, "Daily limit reached. Upgrade to Premium for unlimited sessions.")
        }

        return (true, nil)
    }

    /// Get the number of sessions completed today
    private func getTodaySessionCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let lastSessionDate = UserDefaults.standard.object(forKey: "lastSessionDate") as? Date ?? Date.distantPast
        let sessionCount = UserDefaults.standard.integer(forKey: "todaySessionCount")

        // Reset count if it's a new day
        if !calendar.isDate(lastSessionDate, inSameDayAs: today) {
            return 0
        }

        return sessionCount
    }

    /// Increment today's session count
    private func incrementSessionCount() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let lastSessionDate = UserDefaults.standard.object(forKey: "lastSessionDate") as? Date ?? Date.distantPast
        var sessionCount = UserDefaults.standard.integer(forKey: "todaySessionCount")

        // Reset count if it's a new day
        if !calendar.isDate(lastSessionDate, inSameDayAs: today) {
            sessionCount = 0
        }

        sessionCount += 1
        UserDefaults.standard.set(sessionCount, forKey: "todaySessionCount")
        UserDefaults.standard.set(Date(), forKey: "lastSessionDate")

        updateSessionsRemaining()
    }

    /// Update the sessions remaining count
    private func updateSessionsRemaining() {
        if subscriptionManager.isPremium {
            sessionsRemainingToday = -1 // Unlimited
        } else {
            let used = getTodaySessionCount()
            sessionsRemainingToday = max(0, freeSessionsPerDay - used)
        }
    }

    /// Check if session should stop due to time limit (free tier only)
    private func checkSessionTimeLimit() {
        guard !subscriptionManager.isPremium else { return }

        if sessionDuration >= freeSessionDurationLimit {
            print("⏱️ Free tier session time limit reached (30 minutes)")
            stopMonitoring()
            // Post notification that session ended
            NotificationCenter.default.post(name: .sessionTimeLimitReached, object: nil)
        }
    }

    func startMonitoring() {
        sessionStartTime = Date()
        badPostureCount = 0
        isMonitoring = true
        badPostureStartTime = nil
        lastNotificationTime = nil

        // Increment session count for free tier users
        incrementSessionCount()

        // Request notification permissions
        requestNotificationPermission()

        // Control screen idle timer
        updateScreenIdleTimer()

        // Start timer for session duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
            self?.checkSessionTimeLimit()
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

        // Add icon as notification attachment for richer display
        if let iconImage = UIImage(named: "NotificationIcon"),
           let tempURL = saveImageTemporarily(image: iconImage) {
            if let attachment = try? UNNotificationAttachment(identifier: "icon", url: tempURL, options: nil) {
                content.attachments = [attachment]
            }
        }

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

    private func saveImageTemporarily(image: UIImage) -> URL? {
        guard let imageData = image.pngData() else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "notification-icon-\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save notification image: \(error)")
            return nil
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

// MARK: - Notification Names
extension Notification.Name {
    static let sessionTimeLimitReached = Notification.Name("sessionTimeLimitReached")
}
