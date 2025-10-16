import SwiftUI

struct SettingsView: View {
    @ObservedObject var postureMonitor: PostureMonitor
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Threshold Angle")
                        Spacer()
                        Text("\(Int(postureMonitor.badPostureThreshold))°")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $postureMonitor.badPostureThreshold, in: 15...60, step: 5)

                    Text("Posture is considered bad when head angle exceeds this threshold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Posture Detection")
                }

                Section {
                    HStack {
                        Text("Alert Interval")
                        Spacer()
                        Text("\(Int(postureMonitor.notificationInterval))s")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $postureMonitor.notificationInterval, in: 5...30, step: 5)

                    Text("Time of continuous bad posture before sending notification")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        }
    }
}

#Preview {
    SettingsView(postureMonitor: PostureMonitor())
}
