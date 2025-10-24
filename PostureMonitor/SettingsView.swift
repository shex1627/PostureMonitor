import SwiftUI

struct SettingsView: View {
    @ObservedObject var postureMonitor: PostureMonitor
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false
    @State private var intervalText: String = ""
    @FocusState private var intervalFieldFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                // Premium status section
                if !subscriptionManager.isLoading {
                    if subscriptionManager.isPremium {
                        Section {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Premium Active")
                                        .font(.headline)
                                    if !subscriptionManager.subscriptionType.isEmpty {
                                        Text(subscriptionManager.subscriptionType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        Section {
                            Button(action: { showPaywall = true }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upgrade to Premium")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Unlock unlimited sessions and customization")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // Threshold setting
                Section {
                    HStack {
                        Text("Threshold Angle")
                        if !subscriptionManager.isPremium {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        Spacer()
                        Text("\(Int(postureMonitor.badPostureThreshold))°")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $postureMonitor.badPostureThreshold, in: 15...40, step: 5)
                        .disabled(!subscriptionManager.isPremium)
                        .opacity(subscriptionManager.isPremium ? 1.0 : 0.5)

                    if subscriptionManager.isPremium {
                        Text("Posture is considered bad when head angle exceeds this threshold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Fixed at 25° for free tier. Upgrade to customize (15-40°)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Posture Detection")
                }

                // Notification interval setting
                Section {
                    HStack {
                        Text("Alert Interval (seconds)")
                        if !subscriptionManager.isPremium {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }

                    HStack {
                        TextField("Seconds", text: $intervalText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!subscriptionManager.isPremium)
                            .opacity(subscriptionManager.isPremium ? 1.0 : 0.5)
                            .focused($intervalFieldFocused)
                            .onAppear {
                                intervalText = "\(Int(postureMonitor.notificationInterval))"
                            }
                            .onSubmit {
                                saveIntervalValue()
                            }
                            .onChange(of: intervalFieldFocused) { focused in
                                if !focused {
                                    saveIntervalValue()
                                }
                            }

                        Text("seconds")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }

                    if subscriptionManager.isPremium {
                        Text("Time of continuous bad posture before sending notification (5-40s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Fixed at 15s for free tier. Upgrade to customize (5-40s)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    Toggle("Keep Screen On", isOn: Binding(
                        get: { postureMonitor.keepScreenOn },
                        set: { newValue in
                            postureMonitor.keepScreenOn = newValue
                            postureMonitor.updateScreenIdleTimer()
                        }
                    ))

                    Text("Prevents screen from auto-locking during monitoring sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Display")
                }

                // Legal section
                Section {
                    Link(destination: URL(string: "https://necksense.ftdalpha.com/privacy.html")!) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://necksense.ftdalpha.com/terms.html")!) {
                        HStack {
                            Text("Terms of Use (EULA)")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://necksense.ftdalpha.com/support.html")!) {
                        HStack {
                            Text("Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Legal")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func saveIntervalValue() {
        if let value = Int(intervalText) {
            let clamped = max(5, min(40, value))
            postureMonitor.notificationInterval = TimeInterval(clamped)
            intervalText = "\(clamped)" // Update to show clamped value
        } else {
            // Invalid input, reset to current value
            intervalText = "\(Int(postureMonitor.notificationInterval))"
        }
    }
}

#Preview {
    SettingsView(postureMonitor: PostureMonitor())
}
