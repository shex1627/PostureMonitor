import Foundation
import Adapty

/// Manages subscription status and entitlements using Adapty
class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = true

    static let shared = SubscriptionManager()

    // Access level identifier (configured in Adapty dashboard)
    private let premiumAccessLevel = "premium"

    private init() {
        // Subscription status will be checked after Adapty activation in configure()
    }

    /// Initialize Adapty SDK - call this on app launch
    func configure() {
        let adaptyPublicKey = "public_live_RivNZPO0.gvSmu35EObraqhquq4Zj"

        let configuration = AdaptyConfiguration
            .builder(withAPIKey: adaptyPublicKey)
            .build()

        Adapty.activate(with: configuration) { error in
            if let error = error {
                print("❌ Adapty activation error: \(error)")
            } else {
                print("✅ Adapty activated successfully")
                self.checkSubscriptionStatus()
            }
        }

        // Listen for purchase updates
        Adapty.delegate = self
    }

    /// Check current subscription status
    func checkSubscriptionStatus() {
        isLoading = true

        Adapty.getProfile { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(let profile):
                    // Check if user has premium access level
                    if let accessLevel = profile.accessLevels[self?.premiumAccessLevel ?? "premium"],
                       accessLevel.isActive {
                        self?.isPremium = true
                        print("✅ Premium subscription active")
                    } else {
                        self?.isPremium = false
                        print("ℹ️ Free tier user")
                    }

                case .failure(let error):
                    print("❌ Failed to get profile: \(error)")
                    self?.isPremium = false
                }
            }
        }
    }

    /// Restore purchases
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                let profile = try await Adapty.restorePurchases()
                DispatchQueue.main.async {
                    // Check if restoration gave us premium access
                    let hasAccess = profile.accessLevels[self.premiumAccessLevel]?.isActive ?? false
                    self.isPremium = hasAccess
                    completion(hasAccess, nil)
                    print(hasAccess ? "✅ Purchases restored" : "ℹ️ No purchases to restore")
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Restore failed: \(error)")
                    completion(false, error)
                }
            }
        }
    }

    /// Make a purchase
    func purchase(_ product: AdaptyPaywallProduct, completion: @escaping (Bool, Error?) -> Void) {
        Adapty.makePurchase(product: product) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let purchaseResult):
                    switch purchaseResult {
                    case .userCancelled:
                        print("ℹ️ Purchase cancelled by user")
                        completion(false, nil)

                    case .pending:
                        print("⏳ Purchase pending")
                        completion(false, nil)

                    case .success(let profile, _):
                        let hasAccess = profile.accessLevels[self?.premiumAccessLevel ?? "premium"]?.isActive ?? false
                        self?.isPremium = hasAccess
                        completion(hasAccess, nil)
                        print("✅ Purchase successful")
                    }

                case .failure(let error):
                    print("❌ Purchase failed: \(error)")
                    completion(false, error)
                }
            }
        }
    }
}

// MARK: - AdaptyDelegate
extension SubscriptionManager: AdaptyDelegate {
    func didLoadLatestProfile(_ profile: AdaptyProfile) {
        DispatchQueue.main.async {
            // Update premium status when profile changes
            let hasAccess = profile.accessLevels[self.premiumAccessLevel]?.isActive ?? false
            self.isPremium = hasAccess
            print("📱 Profile updated - Premium: \(hasAccess)")
        }
    }
}
