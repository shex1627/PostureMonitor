import Foundation
import CoreMotion
import AVFoundation

enum AirPodsStatus {
    case notConnected
    case connected
    case connectedIdle  // Connected but not receiving updates
    case tracking       // Actively tracking
    case unsupported    // AirPods don't support motion
}

/// Manages AirPods motion tracking using CMHeadphoneMotionManager
class AirPodsMotionManager: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    private var audioPlayer: AVAudioPlayer?
    private var lastUpdateTime: Date?
    private var statusCheckTimer: Timer?

    @Published var isTracking = false
    @Published var currentAngle: Double = 0.0
    @Published var isAirPodsConnected = false
    @Published var airPodsStatus: AirPodsStatus = .notConnected

    var onPostureUpdate: ((Double) -> Void)?
    var onDisconnect: (() -> Void)?

    init() {
        setupAudioSession()
        checkAvailability()
        startMonitoringAudioRouteChanges()
        startStatusMonitoring()
    }

    func checkAvailability() {
        let wasConnected = isAirPodsConnected

        // Check audio route for connected headphones
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let connectedOutput = currentRoute.outputs.first

        print("🔍 Audio Route Check:")
        print("   Current route outputs: \(currentRoute.outputs.count)")
        print("   Output port type: \(connectedOutput?.portType.rawValue ?? "none")")
        print("   Output port name: \(connectedOutput?.portName ?? "none")")

        // Detect if AirPods are connected (regardless of motion availability)
        let isAirPodsLike = connectedOutput?.portType == .bluetoothA2DP ||
                           connectedOutput?.portType == .bluetoothLE ||
                           connectedOutput?.portType.rawValue == "Bluetooth" // Mac Catalyst
        let outputName = connectedOutput?.portName.lowercased() ?? ""
        let isAirPods = outputName.contains("airpod") // Match "airpod" instead of "airpods" to handle truncation

        print("   Is Bluetooth Audio: \(isAirPodsLike)")
        print("   Is AirPods by name: \(isAirPods)")

        // Check if motion is actually available
        let motionAvailable = motionManager.isDeviceMotionAvailable
        print("   Motion available: \(motionAvailable)")

        if isAirPods || (isAirPodsLike && motionAvailable) {
            // AirPods detected
            isAirPodsConnected = true

            if isTracking && lastUpdateTime != nil {
                airPodsStatus = .tracking
            } else if isTracking {
                airPodsStatus = .connectedIdle
            } else {
                airPodsStatus = .connected
            }
        } else if isAirPodsLike {
            // Bluetooth headphones but not AirPods with motion
            isAirPodsConnected = false
            airPodsStatus = .unsupported
        } else {
            // No headphones
            isAirPodsConnected = false
            airPodsStatus = .notConnected
        }

        // Log status change and notify if disconnected during tracking
        if wasConnected != isAirPodsConnected {
            print("🎧 AirPods status changed: \(airPodsStatus)")
            print("   Output: \(connectedOutput?.portName ?? "none"), Motion: \(motionAvailable)")

            // If AirPods disconnected while tracking, notify
            if !isAirPodsConnected && isTracking {
                DispatchQueue.main.async {
                    self.onDisconnect?()
                }
            }
        }
    }

    func startTracking() {
        // Play wake-up sound first to activate AirPods
        playWakeUpSound()

        // Give AirPods a moment to wake up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            guard self.motionManager.isDeviceMotionAvailable else {
                print("❌ AirPods motion not available after wake-up")
                return
            }

            // Start silent audio to keep AirPods active
            self.startSilentAudio()

            self.motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Motion update error: \(error)")
                    return
                }

                guard let motion = motion else {
                    print("❌ No motion data received")
                    return
                }

                // Get pitch angle (head tilt forward/backward)
                let pitch = motion.attitude.pitch
                let pitchDegrees = pitch * 180.0 / .pi

                // Calculate absolute angle from neutral (0° = looking straight)
                let angle = abs(pitchDegrees)

                print("📊 Angle update: \(Int(angle))° (pitch: \(Int(pitchDegrees))°)")

                DispatchQueue.main.async {
                    self.currentAngle = angle
                    self.lastUpdateTime = Date()
                    self.airPodsStatus = .tracking
                    self.onPostureUpdate?(angle)
                }
            }

            self.isTracking = true
            self.airPodsStatus = .connectedIdle
            print("✅ Started AirPods tracking")
        }
    }

    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        stopSilentAudio()
        isTracking = false
        lastUpdateTime = nil
        checkAvailability() // Update status
        print("Stopped AirPods tracking")
    }

    // MARK: - Audio Session Management

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func startSilentAudio() {
        // Create a silent audio buffer
        let silenceBuffer = createSilenceBuffer()

        do {
            audioPlayer = try AVAudioPlayer(data: silenceBuffer, fileTypeHint: AVFileType.wav.rawValue)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.0 // Silent
            audioPlayer?.play()
            print("🔇 Started silent audio playback")
        } catch {
            print("❌ Failed to start silent audio: \(error)")
        }
    }

    private func stopSilentAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        print("🔇 Stopped silent audio playback")
    }

    private func playWakeUpSound() {
        // Play a brief audible beep to wake up AirPods
        do {
            let wakeUpBuffer = createWakeUpTone()
            let wakeUpPlayer = try AVAudioPlayer(data: wakeUpBuffer, fileTypeHint: AVFileType.wav.rawValue)
            wakeUpPlayer.volume = 0.3 // Moderate volume
            wakeUpPlayer.play()
            print("🔔 Played wake-up tone")

            // Clean up after playback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Player will be deallocated automatically
            }
        } catch {
            print("❌ Failed to play wake-up sound: \(error)")
        }
    }

    private func createWakeUpTone() -> Data {
        // Create a brief 440Hz tone (A note) for 0.2 seconds
        let sampleRate: UInt32 = 44100
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let duration: Double = 0.2 // 200ms

        let numSamples = Int(Double(sampleRate) * duration)
        let dataSize = UInt32(numSamples * Int(channels * bitsPerSample / 8))

        var data = Data()

        // WAV Header
        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + dataSize).littleEndianData)
        data.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(channels.littleEndianData)
        data.append(sampleRate.littleEndianData)
        data.append((sampleRate * UInt32(channels * bitsPerSample / 8)).littleEndianData)
        data.append((channels * bitsPerSample / 8).littleEndianData)
        data.append(bitsPerSample.littleEndianData)

        // data chunk
        data.append("data".data(using: .ascii)!)
        data.append(dataSize.littleEndianData)

        // Generate 440Hz sine wave
        let frequency: Double = 440.0
        for i in 0..<numSamples {
            let sample = sin(2.0 * .pi * frequency * Double(i) / Double(sampleRate))
            let amplitude: Int16 = Int16(sample * 16000.0) // Moderate amplitude
            data.append(amplitude.littleEndianData)
        }

        return data
    }

    private func createSilenceBuffer() -> Data {
        // Create a minimal WAV file with silence
        let sampleRate: UInt32 = 44100
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let duration: UInt32 = 1 // 1 second

        let numSamples = sampleRate * duration
        let dataSize = numSamples * UInt32(channels * bitsPerSample / 8)

        var data = Data()

        // WAV Header
        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + dataSize).littleEndianData)
        data.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData) // chunk size
        data.append(UInt16(1).littleEndianData) // audio format (PCM)
        data.append(channels.littleEndianData)
        data.append(sampleRate.littleEndianData)
        data.append((sampleRate * UInt32(channels * bitsPerSample / 8)).littleEndianData) // byte rate
        data.append((channels * bitsPerSample / 8).littleEndianData) // block align
        data.append(bitsPerSample.littleEndianData)

        // data chunk
        data.append("data".data(using: .ascii)!)
        data.append(dataSize.littleEndianData)

        // Silence samples
        data.append(Data(count: Int(dataSize)))

        return data
    }

    // MARK: - Connection Monitoring

    private func startMonitoringAudioRouteChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleAudioRouteChange(notification: Notification) {
        print("🎧 Audio route changed, checking AirPods availability...")
        DispatchQueue.main.async {
            self.checkAvailability()
        }
    }

    private func startStatusMonitoring() {
        // Check status every 3 seconds to detect idle state
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.isTracking {
                // Check if we're still receiving updates
                if let lastUpdate = self.lastUpdateTime {
                    let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
                    if timeSinceUpdate > 5.0 {
                        // No updates for 5 seconds - mark as idle
                        if self.airPodsStatus == .tracking {
                            self.airPodsStatus = .connectedIdle
                            print("⚠️ AirPods idle - no motion updates for 5s. Make sure AirPods are in your ears.")
                        }
                    }
                }
            }

            // Recheck availability
            self.checkAvailability()
        }
    }

    deinit {
        statusCheckTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        stopTracking()
    }
}

// Helper extension for little endian data
extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<Self>.size)
    }
}
