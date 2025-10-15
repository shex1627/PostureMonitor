import SwiftUI

struct ContentView: View {
    @StateObject private var airpodsManager = AirPodsMotionManager()
    @StateObject private var postureMonitor = PostureMonitor()
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status indicator
                if airpodsManager.isAirPodsConnected {
                    HStack {
                        Image(systemName: "airpodspro")
                            .foregroundColor(.blue)
                        Text("AirPods Connected")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "airpodspro")
                            .foregroundColor(.gray)
                        Text("Connect AirPods Pro/Max")
                            .foregroundColor(.secondary)
                    }
                }

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
                        .background(postureMonitor.isMonitoring ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(!airpodsManager.isAirPodsConnected)
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
        }
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
