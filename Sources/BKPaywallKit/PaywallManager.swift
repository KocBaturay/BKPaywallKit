//
//  PaywallManager.swift
//  BKPaywallKit
//
//  Created by Baturay Koc on 10/18/25.
//

import Foundation
import Combine
import RevenueCat

@MainActor
public final class PaywallManager: ObservableObject {
    @Published public private(set) var offerings: Offerings?
    @Published public private(set) var isPurchasing: Bool = false
    @Published public private(set) var purchaseError: String? = nil
    @Published public private(set) var isSubscriptionActive: Bool = false

    private var cancellables = Set<AnyCancellable>()

    public init(apiKey: String? = nil) {
        if let key = apiKey {
            Purchases.configure(withAPIKey: key)
        }
    }

    public func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            Task { @MainActor in
                if let error = error {
                    self?.purchaseError = "Failed to load offerings: \(error.localizedDescription)"
                    return
                }
                self?.offerings = offerings
            }
        }
    }

    public func purchase(package: Package?, productIdentifier: String? = nil, completion: ((Bool) -> Void)? = nil) {
        isPurchasing = true
        purchaseError = nil

        if let p = package {
            Purchases.shared.purchase(package: p) { [weak self] (transaction, customerInfo, error, userCancelled) in
                Task { @MainActor in
                    self?.handlePurchaseResult(customerInfo: customerInfo, error: error, userCancelled: userCancelled)
                    self?.isPurchasing = false
                    completion?(customerInfo?.entitlements.all["pro"]?.isActive == true)
                }
            }
            return
        }
        
        isPurchasing = false
        purchaseError = "No product available for purchase."
        completion?(false)
    }

    public func restorePurchases(completion: ((Bool) -> Void)? = nil) {
        isPurchasing = true
        Purchases.shared.restorePurchases { [weak self] (customerInfo, error) in
            Task { @MainActor in
                if let error = error {
                    self?.purchaseError = "Restore failed: \(error.localizedDescription)"
                    self?.isPurchasing = false
                    completion?(false)
                    return
                }
                let active = customerInfo?.entitlements.all["pro"]?.isActive == true
                self?.isSubscriptionActive = active
                self?.isPurchasing = false
                completion?(active)
            }
        }
    }

    private func handlePurchaseResult(customerInfo: CustomerInfo?, error: Error?, userCancelled: Bool) {
        if userCancelled {
            self.purchaseError = "User Cancelled"
            return
        }
        if let error = error {
            self.purchaseError = error.localizedDescription
            return
        }
        if customerInfo?.entitlements.all["pro"]?.isActive == true {
            self.isSubscriptionActive = true
        } else {
            self.purchaseError = "Purchase_UnknownState"
        }
    }
}
