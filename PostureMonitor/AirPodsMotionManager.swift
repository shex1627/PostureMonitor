import Foundation
import CoreMotion

/// Manages AirPods motion tracking using CMHeadphoneMotionManager
class AirPodsMotionManager: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()

    @Published var isTracking = false
    @Published var currentAngle: Double = 0.0
    @Published var isAirPodsConnected = false

    var onPostureUpdate: ((Double) -> Void)?

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        isAirPodsConnected = motionManager.isDeviceMotionAvailable
        print("AirPods motion available: \(isAirPodsConnected)")
    }

    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("AirPods motion not available")
            return
        }

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            // Get pitch angle (head tilt forward/backward)
            let pitch = motion.attitude.pitch
            let pitchDegrees = pitch * 180.0 / .pi

            // Calculate absolute angle from neutral (0° = looking straight)
            let angle = abs(pitchDegrees)

            DispatchQueue.main.async {
                self.currentAngle = angle
                self.onPostureUpdate?(angle)
            }
        }

        isTracking = true
        print("Started AirPods tracking")
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
        print("Stopped AirPods tracking")
    }

    deinit {
        stopTracking()
    }
}
