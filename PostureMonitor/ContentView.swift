import SwiftUI

struct ContentView: View {
    @StateObject private var airpodsManager = AirPodsMotionManager()
    @StateObject private var postureMonitor = PostureMonitor()
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status indicator
                statusBanner

                // Current angle display
                VStack(spacing: 10) {
                    Text("\(Int(postureMonitor.currentAngle))°")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(postureMonitor.currentAngle > postureMonitor.badPostureThreshold ? .red : .green)

                    Text("Head Angle")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(postureStatusText)
                        .font(.subheadline)
                        .foregroundColor(postureMonitor.currentAngle > postureMonitor.badPostureThreshold ? .red : .green)
                }
                .padding()

                // Session stats
                if postureMonitor.isMonitoring {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Session Time:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDuration(postureMonitor.sessionDuration))
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Bad Posture Alerts:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(postureMonitor.badPostureCount)")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                // Start/Stop button
                Button(action: toggleMonitoring) {
                    Text(postureMonitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackgroundColor)
                        .cornerRadius(10)
                }
                .disabled(!airpodsManager.isAirPodsConnected)
                .opacity(airpodsManager.isAirPodsConnected ? 1.0 : 0.5)
            }
            .padding()
            .navigationTitle("Posture Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(postureMonitor: postureMonitor)
            }
            .onAppear {
                airpodsManager.checkAvailability()
                setupCallbacks()
            }
            .onChange(of: airpodsManager.isAirPodsConnected) { newValue in
                // Auto-stop monitoring if AirPods disconnect during session
                if !newValue && postureMonitor.isMonitoring {
                    print("⚠️ AirPods disconnected - stopping monitoring")
                    airpodsManager.stopTracking()
                    postureMonitor.stopMonitoring()
                }
            }
        }
    }

    private var statusBanner: some View {
        Group {
            switch airpodsManager.airPodsStatus {
            case .notConnected:
                HStack {
                    Image(systemName: "airpodspro")
                        .foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Not Connected")
                            .foregroundColor(.secondary)
                        Text("Connect AirPods Pro/Max/3rd gen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            case .unsupported:
                HStack {
                    Image(systemName: "airpodspro")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Headphones Not Supported")
                            .foregroundColor(.orange)
                        Text("Requires AirPods Pro, Max, or 3rd gen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

            case .connected:
                HStack {
                    Image(systemName: "airpodspro")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Ready")
                            .foregroundColor(.blue)
                        Text("Tap Start Monitoring to begin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            case .connectedIdle:
                HStack {
                    Image(systemName: "airpodspro")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Idle")
                            .foregroundColor(.yellow)
                        Text("Put AirPods in your ears to track")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)

            case .tracking:
                HStack {
                    Image(systemName: "airpodspro")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tracking Active")
                            .foregroundColor(.green)
                        Text("Monitoring your posture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var buttonBackgroundColor: Color {
        if !airpodsManager.isAirPodsConnected {
            return Color.gray
        }
        return postureMonitor.isMonitoring ? Color.red : Color.blue
    }

    private var postureStatusText: String {
        if postureMonitor.currentAngle > postureMonitor.badPostureThreshold {
            return "Bad Posture - Look Up!"
        } else {
            return "Good Posture ✓"
        }
    }

    private func toggleMonitoring() {
        if postureMonitor.isMonitoring {
            // Stop
            airpodsManager.stopTracking()
            postureMonitor.stopMonitoring()
        } else {
            // Start
            postureMonitor.startMonitoring()
            airpodsManager.startTracking()
        }
    }

    private func setupCallbacks() {
        airpodsManager.onPostureUpdate = { angle in
            postureMonitor.updateAngle(angle)
        }

        airpodsManager.onDisconnect = { [weak postureMonitor, weak airpodsManager] in
            print("⚠️ AirPods disconnected callback - auto-stopping session")
            airpodsManager?.stopTracking()
            postureMonitor?.stopMonitoring()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
