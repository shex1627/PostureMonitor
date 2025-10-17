# Posture Monitor

A native iOS app that uses AirPods motion sensors to track your head posture and send alerts when you're slouching.

## Features

- **Real-time Posture Tracking** - Uses AirPods Pro/Max/3rd gen motion sensors to monitor head angle
- **Smart Notifications** - Receive critical alerts when maintaining bad posture for extended periods
- **AirPods Status Monitoring** - Clear visual feedback about AirPods connection and tracking status
- **Customizable Settings** - Adjust posture threshold, notification intervals, and display options
- **Settings Persistence** - Your preferences are saved across app and device restarts
- **Keep Screen On Mode** - Prevent screen auto-lock during desk work sessions
- **Background Tracking** - Continue monitoring even when app is backgrounded
- **Auto-stop Protection** - Automatically stops session when AirPods disconnect

## Requirements

- iOS 15.0 or later
- AirPods Pro, AirPods Max, or AirPods (3rd generation)
- Xcode 14.0+ (for building from source)

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/PostureMonitor.git
   cd PostureMonitor
   ```

2. Open the project in Xcode:
   ```bash
   open PostureMonitor.xcodeproj
   ```

3. Enable Background Modes capability:
   - Select the project in Xcode
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Background Modes"
   - Check "Audio, AirPlay, and Picture in Picture"

4. Build and run on your device (Simulator won't work - requires real AirPods)

## Usage

### Getting Started

1. **Connect AirPods** - Make sure your AirPods Pro/Max/3rd gen are connected
2. **Check Status** - The app will show your AirPods connection status:
   - Green: Actively tracking
   - Blue: Connected and ready
   - Yellow: Connected but AirPods not in ears
   - Orange: Unsupported headphones
   - Gray: Not connected
3. **Start Monitoring** - Tap "Start Monitoring" to begin tracking
4. **Straighten Up** - When you slouch, you'll receive alerts to correct your posture

### Configuring Settings

Access settings via the gear icon in the top-right corner:

**Posture Detection**
- **Bad Posture Threshold** (15-45°) - Head tilt angle that triggers alerts
- **Notification Interval** (5-30 seconds) - How long to wait before sending repeated alerts

**Display**
- **Keep Screen On** - Prevents screen from auto-locking during monitoring sessions

### Understanding the Display

- **Current Angle** - Real-time head tilt angle (0° is perfectly upright)
- **Session Duration** - How long you've been monitoring
- **Bad Posture Count** - Number of alerts received this session

## Technical Details

### Architecture

The app consists of four main components:

1. **AirPodsMotionManager** - Manages CMHeadphoneMotionManager, audio session, and connection monitoring
2. **PostureMonitor** - Core logic for posture checking, notifications, and settings persistence
3. **ContentView** - SwiftUI main interface with real-time status updates
4. **SettingsView** - Configuration interface for user preferences

### How It Works

- Uses `CMHeadphoneMotionManager` to access AirPods motion data
- Plays silent audio to keep AirPods in active state for continuous tracking
- Monitors audio route changes for real-time connection status
- Sends critical notifications with time-sensitive interruption level
- Uses UserDefaults for persistent settings storage
- Supports background operation via audio background mode

### Privacy

- All motion tracking happens locally on your device
- No data is collected, transmitted, or stored externally
- Motion permission is only used for posture monitoring

## Troubleshooting

### Head angle not updating

- Ensure you've granted motion tracking permission (Settings > Privacy > Motion & Fitness)
- Make sure AirPods are actively worn and detected in your ears
- Check that the status shows "Tracking" in green

### Notifications not appearing

- Grant notification permissions when prompted
- Check that notifications are enabled in Settings > Notifications > Posture Monitor
- Enable Background Modes capability in Xcode (see Installation step 3)

### AirPods not detected

- Verify you have AirPods Pro, AirPods Max, or AirPods (3rd generation)
- Regular AirPods (1st/2nd gen) don't support motion tracking
- Ensure AirPods are connected via Bluetooth Settings

### Background tracking not working

- Make sure "Audio, AirPlay, and Picture in Picture" is enabled in Background Modes
- The app uses silent audio to maintain background operation
- iOS may limit background operation when battery is low

## License

MIT License - See LICENSE file for details

## Acknowledgments

Built with SwiftUI and Core Motion framework. Uses Apple's CMHeadphoneMotionManager API for AirPods motion tracking.
