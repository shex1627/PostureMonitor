# NeckSense User Journey Test Checklist

## Test Environment Setup
- [ ] iPhone with compatible AirPods (Pro, Max, or 3rd gen)
- [ ] App installed via Xcode
- [ ] Sandbox Apple ID created and ready
- [ ] iPhone App Store signed out (Settings → App Store → Sign Out)

---

## 1. Initial App Launch

### 1.1 App Launch with AirPods Disconnected
- [ ] Launch the app
- [ ] **Expected:** Status shows "No AirPods Detected" or similar
- [ ] **Expected:** "Start Monitoring" button is disabled/gray
- [ ] **Expected:** Settings are accessible

### 1.2 Connect AirPods While App is Open
- [ ] Put AirPods in ears
- [ ] Wait for connection
- [ ] **Expected:** Status updates to "AirPods Connected"
- [ ] **Expected:** "Start Monitoring" button becomes blue and clickable
- [ ] **Expected:** Head angle display initializes

### 1.3 App Launch with AirPods Already Connected
- [ ] Close and relaunch app with AirPods in ears
- [ ] **Expected:** App immediately shows "AirPods Connected"
- [ ] **Expected:** "Start Monitoring" button is enabled
- [ ] **Expected:** Head angle displays current position

### 1.4 AirPods in Standby Mode
- [ ] Connect AirPods but don't play any audio
- [ ] Launch app
- [ ] **Expected:** App detects AirPods
- [ ] **Expected:** Motion data may be delayed until audio plays
- [ ] **Action:** Play a video or music briefly to activate sensors
- [ ] **Expected:** Head angle updates start appearing

---

## 2. Settings Persistence

### 2.1 Change Settings and Close App
- [ ] Open Settings
- [ ] Change posture threshold (e.g., to 45°)
- [ ] Change alert interval (e.g., to 20 seconds)
- [ ] Toggle "Keep Screen On" to ON
- [ ] Close the app completely (swipe up from app switcher)
- [ ] **Expected:** All settings are saved

### 2.2 Reopen App
- [ ] Relaunch the app
- [ ] Open Settings
- [ ] **Expected:** Threshold is 45°
- [ ] **Expected:** Alert interval is 20 seconds
- [ ] **Expected:** "Keep Screen On" is still ON
- [ ] Console shows: `📱 Loaded settings - Threshold: 45°, Interval: 20s, Keep Screen On: true`

### 2.3 Restart Phone
- [ ] Restart iPhone
- [ ] Launch app after restart
- [ ] Check Settings
- [ ] **Expected:** All custom settings persist after phone restart

---

## 3. Free Tier Limits

### 3.1 Daily Session Count Limit (3 sessions/day)

**Session 1:**
- [ ] Start monitoring session
- [ ] Stop after 5 minutes
- [ ] **Expected:** Console shows session count: `1/3 sessions used today`

**Session 2:**
- [ ] Start new monitoring session
- [ ] Stop after 5 minutes
- [ ] **Expected:** Console shows: `2/3 sessions used today`

**Session 3:**
- [ ] Start new monitoring session
- [ ] Stop after 5 minutes
- [ ] **Expected:** Console shows: `3/3 sessions used today`

**Session 4 Attempt:**
- [ ] Try to start another session
- [ ] **Expected:** Alert appears: "Daily limit reached. Upgrade to Premium for unlimited sessions."
- [ ] **Expected:** Session does NOT start
- [ ] **Expected:** "Upgrade to Premium" button appears or paywall opens

### 3.2 Session Time Limit (30 minutes per session)
- [ ] Start a new monitoring session (on a fresh day)
- [ ] Let it run for 30 minutes
- [ ] **Expected:** At 30:00, session automatically stops
- [ ] **Expected:** Alert appears: "Free tier session limit reached (30 minutes)"
- [ ] **Expected:** Console shows: `⏱️ Free tier session time limit reached (30 minutes)`
- [ ] **Expected:** Option to upgrade appears

### 3.3 Settings Locked for Free Tier
- [ ] Open Settings as free user
- [ ] Try to adjust Posture Threshold slider
- [ ] **Expected:** Slider is disabled/grayed out
- [ ] **Expected:** Shows: "Threshold: 30° (Premium: 15-60°)"
- [ ] Try to adjust Alert Interval slider
- [ ] **Expected:** Slider is disabled/grayed out
- [ ] **Expected:** Shows: "Interval: 15s (Premium: 5-30s)"

### 3.4 Session Reset Next Day
- [ ] Use all 3 sessions in one day
- [ ] Wait until next day (or manually change device date for testing)
- [ ] Launch app
- [ ] **Expected:** Session count resets to 0/3
- [ ] **Expected:** Can start monitoring again

---

## 4. Mid-Session Scenarios

### 4.1 AirPods Connection Lost During Session
- [ ] Start a monitoring session
- [ ] Wait 2 minutes
- [ ] Remove AirPods from ears (disconnect them)
- [ ] **Expected:** Session automatically ends
- [ ] **Expected:** Status updates to "AirPods Disconnected"
- [ ] **Expected:** Alert or notification about connection loss
- [ ] Console shows: `🎧 AirPods disconnected`

### 4.2 Head Angle Behavior After Reconnection
- [ ] Start a session
- [ ] Note the current head angle (e.g., 25°)
- [ ] Disconnect and reconnect AirPods
- [ ] **Expected:** Head angle resets/recalibrates
- [ ] **Expected:** New baseline is established
- [ ] **Question to verify:** Does it reset to 0° or maintain previous calibration?

### 4.3 Poor Posture Alert Triggering
- [ ] Start monitoring
- [ ] Tilt head down beyond threshold (default 30°)
- [ ] Wait for alert interval (default 15 seconds)
- [ ] **Expected:** Haptic feedback/notification fires
- [ ] **Expected:** Alert sound plays
- [ ] Console shows: `⚠️ Poor posture detected`

### 4.4 App Backgrounded During Session
- [ ] Start monitoring
- [ ] Press home button (app goes to background)
- [ ] Wait 1 minute
- [ ] Return to app
- [ ] **Expected:** Session is still active
- [ ] **Expected:** Time continues counting
- [ ] **Question to verify:** Does monitoring continue in background?

---

## 5. Premium Subscription Flow

### 5.1 Open Paywall

**From Settings:**
- [ ] Tap Settings
- [ ] Tap "Upgrade to Premium" button
- [ ] **Expected:** Paywall opens

**From Session Limit:**
- [ ] Hit 3 session limit or 30-minute limit
- [ ] Tap upgrade prompt
- [ ] **Expected:** Paywall opens

### 5.2 Paywall Display
- [ ] Verify paywall shows all 3 products:
  - [ ] Monthly: $2.99/month
  - [ ] Yearly: $19.99/year (shows "BEST VALUE" badge)
  - [ ] Lifetime: $29.99 one-time
- [ ] Verify "Yearly" is pre-selected
- [ ] Verify feature list shows:
  - [ ] Unlimited Sessions
  - [ ] Full Customization
  - [ ] Priority Support
  - [ ] All Future Features

### 5.3 Legal Links
- [ ] Tap "Terms" link
- [ ] **Expected:** Opens https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ in Safari
- [ ] Verify Terms page loads correctly (Apple's standard EULA)
- [ ] Return to app
- [ ] Tap "Privacy Policy" link
- [ ] **Expected:** Opens https://necksense.ftdalpha.com/privacy.html in Safari
- [ ] Verify Privacy page loads correctly

### 5.4 Purchase Flow (Sandbox)

**Prerequisites:**
- [ ] iPhone App Store is signed out
- [ ] Sandbox test account created

**Purchase:**
- [ ] Select "Lifetime" product ($29.99)
- [ ] Tap "Continue"
- [ ] **Expected:** iOS prompts for Apple ID
- [ ] Enter sandbox account credentials
- [ ] **Expected:** Purchase dialog shows "[Environment: Sandbox]"
- [ ] Confirm purchase
- [ ] **Expected:** Purchase completes successfully
- [ ] Console shows:
  ```
  Successfully purchased product: com.shex1627.posturemonitor.premium.lifetime
  📱 Profile updated - Premium: true
  ```

### 5.5 Premium Features Unlocked
- [ ] Close paywall
- [ ] **Expected:** Premium badge/indicator appears
- [ ] Open Settings
- [ ] **Expected:** Threshold slider is now enabled (15-60°)
- [ ] **Expected:** Interval slider is now enabled (5-30s)
- [ ] Start a monitoring session
- [ ] **Expected:** No time limit warning at 30 minutes
- [ ] Stop and start multiple sessions
- [ ] **Expected:** No daily session limit

### 5.6 Restore Purchases
- [ ] Delete the app from iPhone
- [ ] Reinstall via Xcode
- [ ] Launch app
- [ ] **Expected:** Shows as free tier initially
- [ ] Open paywall
- [ ] Tap "Restore Purchases"
- [ ] Sign in with same sandbox account
- [ ] **Expected:** Premium status restored
- [ ] **Expected:** No new purchase required
- [ ] Console shows:
  ```
  ✅ Purchases restored successfully
  📱 Profile updated - Premium: true
  ```

---

## 6. Edge Cases

### 6.1 Multiple AirPods Devices
- [ ] Pair multiple AirPods to iPhone
- [ ] Switch between them
- [ ] **Expected:** App detects the active AirPods
- [ ] **Question to verify:** Does it handle device switching gracefully?

### 6.2 Low Battery Scenario
- [ ] Use app with AirPods at low battery (<20%)
- [ ] **Expected:** App continues working
- [ ] AirPods die during session
- [ ] **Expected:** Session ends gracefully

### 6.3 Phone Call During Session
- [ ] Start monitoring
- [ ] Receive or make a phone call
- [ ] **Question to verify:** Does session pause or continue?
- [ ] End call
- [ ] **Question to verify:** Does session resume?

### 6.4 Airplane Mode
- [ ] Enable Airplane Mode
- [ ] Start monitoring with connected AirPods
- [ ] **Expected:** Monitoring works (local processing)
- [ ] Try to purchase subscription
- [ ] **Expected:** Shows connection error (needs internet for Adapty)

---

## 7. Console Log Validation

### Expected Success Logs:
- [ ] `✅ Audio session configured`
- [ ] `📱 Loaded settings - Threshold: X°, Interval: Xs, Keep Screen On: true/false`
- [ ] `✅ Adapty activated successfully`
- [ ] `📱 Profile updated - Premium: true/false`
- [ ] `✅ Paywall loaded: main_paywall`
- [ ] `✅ Loaded 3 products`

### Expected During Usage:
- [ ] Head angle updates continuously
- [ ] `⚠️ Poor posture detected` when threshold exceeded
- [ ] `⏱️ Session ended after X minutes`

### Should NOT See:
- [ ] `❌ Failed to load products` (indicates Adapty config issue)
- [ ] `❌ Failed to load paywall` (indicates network/Adapty issue)
- [ ] Continuous error loops
- [ ] StoreKit errors on real device with sandbox account

---

## 8. Performance & Stability

### 8.1 Battery Usage
- [ ] Run monitoring for 1 hour
- [ ] Note battery drain percentage
- [ ] **Acceptable:** Reasonable battery usage for motion tracking

### 8.2 Memory Usage
- [ ] Monitor app memory in Xcode
- [ ] Run session for extended period
- [ ] **Expected:** No memory leaks
- [ ] **Expected:** Stable memory usage

### 8.3 App Responsiveness
- [ ] UI remains responsive during monitoring
- [ ] No lag when opening settings
- [ ] Paywall loads quickly (<2 seconds)
- [ ] No freezing or crashes

---

## Test Results Summary

**Tester:** ________________
**Date:** ________________
**Device:** ________________
**iOS Version:** ________________
**App Version:** ________________

**Overall Pass/Fail:** ________________

**Issues Found:**
1.
2.
3.

**Notes:**
