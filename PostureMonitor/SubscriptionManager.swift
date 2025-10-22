import Foundation
import Adapty

/// Manages subscription status and entitlements using Adapty
class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = true
    @Published var subscriptionType: String = "" // "Monthly", "Yearly", "Lifetime", or empty

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

                        // Determine subscription type from vendor product ID
                        let vendorProductId = accessLevel.vendorProductId
                        if !vendorProductId.isEmpty {
                            self?.subscriptionType = self?.getSubscriptionType(from: vendorProductId) ?? "Premium"
                            print("✅ Premium subscription active: \(self?.subscriptionType ?? "")")
                        } else {
                            self?.subscriptionType = "Premium"
                            print("✅ Premium subscription active")
                        }
                    } else {
                        self?.isPremium = false
                        self?.subscriptionType = ""
                        print("ℹ️ Free tier user")
                    }

                case .failure(let error):
                    print("❌ Failed to get profile: \(error)")
                    self?.isPremium = false
                    self?.subscriptionType = ""
                }
            }
        }
    }

    /// Determine subscription type from product ID
    private func getSubscriptionType(from productId: String) -> String {
        if productId.contains("monthly") {
            return "Monthly"
        } else if productId.contains("yearly") {
            return "Yearly"
        } else if productId.contains("lifetime") {
            return "Lifetime"
        } else {
            return "Premium"
        }
    }

    /// Restore purchases
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                let profile = try await Adapty.restorePurchases()
                DispatchQueue.main.async {
                    // Check if restoration gave us premium access
                    let accessLevel = profile.accessLevels[self.premiumAccessLevel]
                    let hasAccess = accessLevel?.isActive ?? false
                    self.isPremium = hasAccess

                    if hasAccess, let accessLevel = accessLevel, !accessLevel.vendorProductId.isEmpty {
                        self.subscriptionType = self.getSubscriptionType(from: accessLevel.vendorProductId)
                    } else {
                        self.subscriptionType = ""
                    }

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
                        let accessLevel = profile.accessLevels[self?.premiumAccessLevel ?? "premium"]
                        let hasAccess = accessLevel?.isActive ?? false
                        self?.isPremium = hasAccess

                        if hasAccess, let accessLevel = accessLevel, !accessLevel.vendorProductId.isEmpty {
                            self?.subscriptionType = self?.getSubscriptionType(from: accessLevel.vendorProductId) ?? "Premium"
                        } else {
                            self?.subscriptionType = ""
                        }

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
            let accessLevel = profile.accessLevels[self.premiumAccessLevel]
            let hasAccess = accessLevel?.isActive ?? false
            self.isPremium = hasAccess

            if hasAccess, let accessLevel = accessLevel, !accessLevel.vendorProductId.isEmpty {
                self.subscriptionType = self.getSubscriptionType(from: accessLevel.vendorProductId)
            } else {
                self.subscriptionType = ""
            }

            print("📱 Profile updated - Premium: \(hasAccess), Type: \(self.subscriptionType)")
        }
    }
}
