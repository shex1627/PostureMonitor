import SwiftUI

struct ContentView: View {
    @StateObject private var airpodsManager = AirPodsMotionManager()
    @StateObject private var postureMonitor = PostureMonitor()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showSessionLimitAlert = false
    @State private var sessionLimitMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status indicator
                statusBanner

                // Free tier session info
                if !subscriptionManager.isPremium && !postureMonitor.isMonitoring && !subscriptionManager.isLoading {
                    sessionLimitBanner
                }

                // Current metrics display (only when monitoring)
                if postureMonitor.isMonitoring {
                    VStack(spacing: 20) {
                        // Two-axis display
                        HStack(spacing: 50) {
                            // Pitch - "Forward Tilt"
                            VStack(spacing: 5) {
                                Text("\(Int(postureMonitor.currentMetrics.pitchAbs))°")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(postureMonitor.pitchEnabled && postureMonitor.currentMetrics.pitchAbs > postureMonitor.pitchThreshold ? .red : (postureMonitor.pitchEnabled ? .green : .gray))
                                Text("Forward Tilt")
                                    .font(.caption)
                                    .foregroundColor(postureMonitor.pitchEnabled ? .secondary : .gray)
                                if !postureMonitor.pitchEnabled {
                                    Text("(off)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(postureMonitor.pitchEnabled ? 1.0 : 0.5)

                            // Roll - "Side Tilt"
                            VStack(spacing: 5) {
                                Text("\(Int(postureMonitor.currentMetrics.rollAbs))°")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(postureMonitor.rollEnabled && postureMonitor.currentMetrics.rollAbs > postureMonitor.rollThreshold ? .red : (postureMonitor.rollEnabled ? .green : .gray))
                                Text("Side Tilt")
                                    .font(.caption)
                                    .foregroundColor(postureMonitor.rollEnabled ? .secondary : .gray)
                                if !postureMonitor.rollEnabled {
                                    Text("(off)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(postureMonitor.rollEnabled ? 1.0 : 0.5)
                        }

                        Text(postureStatusText)
                            .font(.subheadline)
                            .foregroundColor(isPostureBad ? .red : .green)
                    }
                    .padding()
                }

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
            .navigationTitle("Neck Sense")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Session Limit Reached", isPresented: $showSessionLimitAlert) {
                Button("Upgrade to Premium") {
                    showPaywall = true
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(sessionLimitMessage)
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
            .onReceive(NotificationCenter.default.publisher(for: .sessionTimeLimitReached)) { _ in
                // Session time limit reached (30 minutes for free tier)
                // Stop the session
                airpodsManager.stopTracking()
                postureMonitor.stopMonitoring()

                // Show alert
                sessionLimitMessage = "Your free session limit of 30 minutes has been reached. Upgrade to Premium for unlimited session duration!"
                showSessionLimitAlert = true
            }
        }
    }

    private var statusBanner: some View {
        Group {
            switch airpodsManager.airPodsStatus {
            case .notConnected:
                HStack {
                    Image(systemName: "headphones")
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
                    Image(systemName: "headphones")
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
                    Image(systemName: "headphones")
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
                    Image(systemName: "headphones")
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
                    Image(systemName: "headphones")
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

    private var isPostureBad: Bool {
        (postureMonitor.pitchEnabled && postureMonitor.currentMetrics.pitchAbs > postureMonitor.pitchThreshold) ||
        (postureMonitor.rollEnabled && postureMonitor.currentMetrics.rollAbs > postureMonitor.rollThreshold)
    }

    private var postureStatusText: String {
        if isPostureBad {
            var issues: [String] = []
            if postureMonitor.pitchEnabled && postureMonitor.currentMetrics.pitchAbs > postureMonitor.pitchThreshold {
                issues.append("neck too far forward")
            }
            if postureMonitor.rollEnabled && postureMonitor.currentMetrics.rollAbs > postureMonitor.rollThreshold {
                issues.append("head tilted to side")
            }
            return "Bad Posture: \(issues.joined(separator: ", "))"
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
            // Check if user can start a new session
            let (canStart, reason) = postureMonitor.canStartSession()

            if canStart {
                // Start
                postureMonitor.startMonitoring()
                airpodsManager.startTracking()
            } else {
                // Show limit message
                sessionLimitMessage = reason ?? "Session limit reached"
                showSessionLimitAlert = true
            }
        }
    }

    private func setupCallbacks() {
        airpodsManager.onPostureUpdate = { metrics in
            postureMonitor.updateMetrics(metrics)
        }

        airpodsManager.onDisconnect = { [weak postureMonitor, weak airpodsManager] in
            print("⚠️ AirPods disconnected callback - auto-stopping session")
            airpodsManager?.stopTracking()
            postureMonitor?.stopMonitoring()
        }
    }

    private var sessionLimitBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                        Text("Free Tier: \(postureMonitor.sessionsRemainingToday)/3 sessions today")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text("30 min per session • Tap to upgrade for unlimited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
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
