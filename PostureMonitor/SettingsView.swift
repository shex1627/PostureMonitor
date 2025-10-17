import SwiftUI

struct SettingsView: View {
    @ObservedObject var postureMonitor: PostureMonitor
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            Form {
                // Premium status section
                if subscriptionManager.isPremium {
                    Section {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Active")
                                .font(.headline)
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
                    Slider(value: $postureMonitor.badPostureThreshold, in: 15...60, step: 5)
                        .disabled(!subscriptionManager.isPremium)
                        .opacity(subscriptionManager.isPremium ? 1.0 : 0.5)

                    if subscriptionManager.isPremium {
                        Text("Posture is considered bad when head angle exceeds this threshold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Fixed at 30° for free tier. Upgrade to customize (15-60°)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Posture Detection")
                }

                // Notification interval setting
                Section {
                    HStack {
                        Text("Alert Interval")
                        if !subscriptionManager.isPremium {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        Spacer()
                        Text("\(Int(postureMonitor.notificationInterval))s")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $postureMonitor.notificationInterval, in: 5...30, step: 5)
                        .disabled(!subscriptionManager.isPremium)
                        .opacity(subscriptionManager.isPremium ? 1.0 : 0.5)

                    if subscriptionManager.isPremium {
                        Text("Time of continuous bad posture before sending notification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Fixed at 15s for free tier. Upgrade to customize (5-30s)")
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
}

#Preview {
    SettingsView(postureMonitor: PostureMonitor())
}
