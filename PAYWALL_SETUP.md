# Paywall Integration Setup Guide

This guide walks you through setting up the premium subscription system for Posture Monitor using Adapty.

## Overview

The app now includes a freemium model with:

**Free Tier:**
- Fixed settings (30° threshold, 15s notification interval)
- Max 3 sessions per day
- 30 minutes per session limit
- Basic posture tracking and notifications

**Premium Tier ($2.99/month, $19.99/year, or $29.99 lifetime):**
- Full customization (15-60° threshold, 5-30s intervals)
- Unlimited daily sessions
- No time limits
- Priority support
- All future premium features

## Step 1: Add Adapty SDK via Swift Package Manager

1. Open `PostureMonitor.xcodeproj` in Xcode
2. Go to **File > Add Package Dependencies...**
3. Enter Adapty SDK URL: `https://github.com/adaptyteam/AdaptySDK-iOS`
4. Select **Up to Next Major Version** with `2.0.0`
5. Click **Add Package**
6. Select both **Adapty** and **AdaptyUI** targets
7. Click **Add Package**

## Step 2: Create Adapty Account and Get API Key

1. Go to [https://adapty.io](https://adapty.io) and sign up
2. Create a new app in Adapty dashboard
3. Navigate to **App Settings > General**
4. Copy your **Public SDK Key**

## Step 3: Configure Adapty API Key

1. Open `SubscriptionManager.swift`
2. Find line ~14: `let adaptyPublicKey = "YOUR_ADAPTY_PUBLIC_KEY"`
3. Replace with your actual Adapty public SDK key:
   ```swift
   let adaptyPublicKey = "public_live_xxxxx..."
   ```

## Step 4: Configure App Store Connect

### Create In-App Purchase Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app (create one if needed)
3. Go to **Features > In-App Purchases**
4. Create three products:

#### Monthly Subscription
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Premium Monthly
- **Product ID**: `posture_monitor_premium_monthly`
- **Subscription Group**: Premium (create if needed)
- **Subscription Duration**: 1 month
- **Price**: $2.99

#### Yearly Subscription
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Premium Yearly
- **Product ID**: `posture_monitor_premium_yearly`
- **Subscription Group**: Premium (same as monthly)
- **Subscription Duration**: 1 year
- **Price**: $19.99

#### Lifetime Purchase
- **Type**: Non-Consumable
- **Reference Name**: Premium Lifetime
- **Product ID**: `posture_monitor_premium_lifetime`
- **Price**: $29.99

5. For each product, fill in:
   - Display name (e.g., "Premium Monthly")
   - Description (e.g., "Unlock unlimited sessions and customization")
   - Review screenshot (use app screenshot)

6. Submit products for review

## Step 5: Configure Adapty Dashboard

### Connect to App Store

1. In Adapty dashboard, go to **App Settings > iOS SDK**
2. Enter your **Bundle ID** (e.g., `com.yourcompany.posturemonitor`)
3. Go to **App Settings > App Store Connect**
4. Follow Adapty's guide to connect your App Store Connect account

### Create Products in Adapty

1. Go to **Products** in Adapty dashboard
2. Create three products matching your App Store products:
   - Monthly: `posture_monitor_premium_monthly`
   - Yearly: `posture_monitor_premium_yearly`
   - Lifetime: `posture_monitor_premium_lifetime`

### Create Access Level

1. Go to **Access Levels**
2. Create access level: `premium`
3. Link all three products to this access level

### Create Paywall

1. Go to **Paywalls**
2. Create paywall: `main_paywall`
3. Add all three products to this paywall
4. Set as default paywall
5. Save changes

## Step 6: Configure Signing & Capabilities

1. In Xcode, select **PostureMonitor** target
2. Go to **Signing & Capabilities** tab
3. Add **In-App Purchase** capability:
   - Click **+ Capability**
   - Search for "In-App Purchase"
   - Add it
4. Ensure your Apple Developer account is selected under **Team**

## Step 7: Test Subscription Flow

### Setup Sandbox Testing

1. In Xcode, go to **Product > Scheme > Edit Scheme...**
2. Select **Run** > **Options** tab
3. Set **StoreKit Configuration** to your `.storekit` file (create one if needed)
4. Or test with sandbox tester account:
   - Go to **Settings** > **App Store** > **Sandbox Account** on your device
   - Sign in with sandbox tester (create in App Store Connect)

### Test the Flow

1. Build and run on a real device (Simulator won't work for IAP)
2. Test free tier limits:
   - Start 3 sessions to hit daily limit
   - Try adjusting settings (should be locked)
   - Start a session and wait 30 minutes (should auto-stop)
3. Test upgrade flow:
   - Tap "Upgrade to Premium" in settings
   - Complete a test purchase
   - Verify settings unlock
   - Verify session limits removed
4. Test restore purchases:
   - Delete and reinstall app
   - Tap "Restore Purchases" in paywall
   - Verify premium status restored

## Step 8: Update Privacy Policy & Terms

Before releasing, ensure you have:

1. **Privacy Policy** that mentions:
   - In-app purchases
   - Adapty usage for subscription management
   - Data collection (if any)

2. **Terms of Service** that mentions:
   - Subscription terms
   - Auto-renewal details
   - Cancellation policy
   - Refund policy

3. Update URLs in `PaywallView.swift` (lines ~186-187):
   ```swift
   Link("Terms", destination: URL(string: "https://yourapp.com/terms")!)
   Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
   ```

## Step 9: Prepare for App Store Review

### Required Information

1. **App Review Information** in App Store Connect:
   - Demo account credentials (if needed)
   - Notes explaining subscription flow
   - Screenshot showing paywall

2. **App Privacy** section:
   - Declare data types collected
   - Link privacy policy

3. **Subscriptions** section:
   - Promotional text
   - Marketing screenshot

### Testing Checklist

- [ ] All three purchase options work
- [ ] Restore purchases works
- [ ] Subscription status persists across app restarts
- [ ] Free tier limits work correctly
- [ ] Premium unlocks all features
- [ ] Graceful handling of failed purchases
- [ ] Privacy policy and terms links work
- [ ] No crashes during purchase flow

## Architecture Overview

### Key Files

- **SubscriptionManager.swift** - Handles Adapty SDK and subscription state
- **PaywallView.swift** - Premium subscription UI
- **PostureMonitor.swift** - Session limits and free tier logic
- **SettingsView.swift** - Locked settings UI for free tier
- **ContentView.swift** - Session limit alerts and upgrade prompts
- **PostureMonitorApp.swift** - Adapty initialization

### Data Flow

1. App launches → `PostureMonitorApp` initializes Adapty
2. Adapty checks subscription status → Updates `SubscriptionManager.isPremium`
3. `PostureMonitor` checks `isPremium` → Enforces limits or allows unlimited
4. User hits limit → Shows alert with upgrade option
5. User taps upgrade → Shows `PaywallView`
6. User purchases → Adapty processes → Updates `isPremium` → Unlocks features

## Monitoring and Analytics

### Adapty Dashboard

Monitor key metrics in Adapty:
- **MRR** (Monthly Recurring Revenue)
- **Conversion rate** (free → premium)
- **Churn rate**
- **Trial conversion**
- **Revenue by product**

### A/B Testing (Future)

Adapty supports A/B testing for:
- Pricing
- Product combinations
- Paywall UI
- Trial offers

## Troubleshooting

### "Adapty activation error"
- Check API key in `SubscriptionManager.swift`
- Verify network connection
- Check Adapty dashboard for app configuration

### "Failed to load paywall"
- Ensure paywall `main_paywall` exists in Adapty dashboard
- Check products are linked to paywall
- Verify products match App Store product IDs

### "Purchase failed"
- Check product IDs match exactly between code, Adapty, and App Store
- Verify In-App Purchase capability is enabled
- Check Apple Developer account status
- Test with sandbox account

### "Subscription not detected"
- Wait 1-2 minutes for Adapty to sync
- Call `SubscriptionManager.shared.checkSubscriptionStatus()` manually
- Check receipt validation in Adapty dashboard

### Settings still locked after purchase
- Check `SubscriptionManager.isPremium` value
- Verify access level is set to `premium` in Adapty
- Check Adapty logs for profile updates

## Next Steps

1. Complete all setup steps above
2. Test thoroughly with TestFlight
3. Submit for App Store review
4. Monitor conversion metrics in Adapty
5. Consider adding analytics (like Mixpanel or Amplitude)
6. Plan v2 features (history, analytics) for future premium tier

## Support

- **Adapty Documentation**: https://docs.adapty.io
- **Adapty Support**: support@adapty.io
- **Apple IAP Guide**: https://developer.apple.com/in-app-purchase/

## Pricing Rationale

**$2.99/month** - Affordable impulse purchase, competitive with health apps
**$19.99/year** - 44% savings, under $20 psychological threshold
**$29.99 lifetime** - Best value, equals 10 months of monthly, attracts commitment-phobes

Free tier is generous enough to prove value, but limited enough to drive conversions.
