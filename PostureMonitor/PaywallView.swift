import SwiftUI
import Adapty

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var paywall: AdaptyPaywall?
    @State private var products: [AdaptyPaywallProduct] = []
    @State private var selectedProduct: AdaptyPaywallProduct?
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .padding(.top, 20)

                            Text("Upgrade to Premium")
                                .font(.system(size: 28, weight: .bold))

                            Text("Unlock unlimited sessions and full customization")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 8)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "infinity", title: "Unlimited Sessions", description: "No daily limits or time caps")
                            FeatureRow(icon: "slider.horizontal.3", title: "Full Customization", description: "Adjust threshold (15-45°) and intervals (5-30s)")
                            FeatureRow(icon: "crown.fill", title: "Priority Support", description: "Get help when you need it")
                            FeatureRow(icon: "lock.shield.fill", title: "All Future Features", description: "Get access to upcoming premium features")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        // Products - Compact horizontal layout
                        if isLoading {
                            ProgressView("Loading plans...")
                                .padding()
                        } else if !products.isEmpty {
                            HStack(spacing: 12) {
                                ForEach(products, id: \.vendorProductId) { product in
                                    CompactProductOption(
                                        product: product,
                                        isSelected: selectedProduct?.vendorProductId == product.vendorProductId,
                                        onSelect: { selectedProduct = product }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Purchase button
                        Button(action: purchaseSelected) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedProduct != nil ? Color.blue : Color.gray)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(selectedProduct == nil || isPurchasing)

                        // Restore button
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 8)

                        // Terms and privacy
                        HStack(spacing: 4) {
                            Text("By subscribing, you agree to our")
                                .font(.caption2)
                            Link("Terms", destination: URL(string: "https://shex1627.github.io/PostureMonitor/terms.html")!)
                            Text("and")
                                .font(.caption2)
                            Link("Privacy Policy", destination: URL(string: "https://shex1627.github.io/PostureMonitor/privacy.html")!)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear(perform: loadPaywall)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func loadPaywall() {
        isLoading = true

        Task {
            do {
                // Load the paywall from Adapty using placementId
                let paywall = try await Adapty.getPaywall(placementId: "main_paywall")

                await MainActor.run {
                    self.paywall = paywall
                }

                await loadProducts(for: paywall)

            } catch {
                await MainActor.run {
                    print("❌ Failed to load paywall: \(error)")
                    isLoading = false
                    errorMessage = "Failed to load subscription options. Please try again."
                    showError = true
                }
            }
        }
    }

    private func loadProducts(for paywall: AdaptyPaywall) async {
        do {
            let products = try await Adapty.getPaywallProducts(paywall: paywall)

            await MainActor.run {
                isLoading = false
                self.products = products

                // Auto-select yearly plan (usually best value)
                if let yearlyProduct = products.first(where: { $0.subscriptionPeriod?.unit == .year }) {
                    selectedProduct = yearlyProduct
                } else {
                    selectedProduct = products.first
                }
            }

        } catch {
            await MainActor.run {
                print("❌ Failed to load products: \(error)")
                isLoading = false
                errorMessage = "Failed to load subscription options. Please try again."
                showError = true
            }
        }
    }

    private func purchaseSelected() {
        guard let product = selectedProduct else { return }

        isPurchasing = true

        subscriptionManager.purchase(product) { success, error in
            isPurchasing = false

            if success {
                // Purchase successful - dismiss paywall
                dismiss()
            } else {
                // Show error
                errorMessage = error?.localizedDescription ?? "Purchase failed. Please try again."
                showError = true
            }
        }
    }

    private func restorePurchases() {
        isPurchasing = true

        subscriptionManager.restorePurchases { success, error in
            isPurchasing = false

            if success {
                // Restoration successful
                dismiss()
            } else {
                errorMessage = "No purchases found to restore."
                showError = true
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Compact Product Option
struct CompactProductOption: View {
    let product: AdaptyPaywallProduct
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Duration label
                Text(durationLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)

                // Price
                Text(product.localizedPrice ?? "")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)

                // Price per month for subscriptions
                if let period = product.subscriptionPeriod {
                    Text(pricePerMonth(product, period: period))
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .green)
                }

                // Best value badge for yearly
                if isYearly {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isSelected ? .white : .green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var durationLabel: String {
        if let period = product.subscriptionPeriod {
            switch period.unit {
            case .month:
                return "Monthly"
            case .year:
                return "Yearly"
            case .week:
                return "Weekly"
            case .day:
                return "Daily"
            @unknown default:
                return "Subscription"
            }
        }
        return "Lifetime"
    }

    private var isYearly: Bool {
        product.subscriptionPeriod?.unit == .year
    }

    private func pricePerMonth(_ product: AdaptyPaywallProduct, period: AdaptySubscriptionPeriod) -> String {
        let price = product.price

        let months: Decimal
        switch period.unit {
        case .month:
            months = Decimal(period.numberOfUnits)
        case .year:
            months = Decimal(period.numberOfUnits * 12)
        case .week:
            months = Decimal(period.numberOfUnits) / 4
        case .day:
            months = Decimal(period.numberOfUnits) / 30
        @unknown default:
            return ""
        }

        let pricePerMonth = price / months
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.currencyCode
        formatter.maximumFractionDigits = 2

        if let formattedPrice = formatter.string(from: pricePerMonth as NSNumber) {
            return "\(formattedPrice)/mo"
        }

        return ""
    }
}

#Preview {
    PaywallView()
}
