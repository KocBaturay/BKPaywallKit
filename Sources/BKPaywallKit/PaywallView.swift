//
//  PaywallView.swift
//  BKPaywallKit
//
//  Created by Baturay Koc on 10/18/25.
//

import SwiftUI
import AVKit
import Combine
import RevenueCat

public struct PaywallView: View {
    @ObservedObject public var manager: PaywallManager
    public var configuration: PaywallConfiguration
    public var onClose: (() -> Void)?
    public var onPurchaseSuccess: (() -> Void)?
    public var onPurchaseFailure: ((String) -> Void)?

    @State private var selectedProduct: ProductType
    @State private var closeButtonTimeRemaining: Int
    @State private var showCloseButton: Bool = false
    @State private var remoteConfigHideCloseButton: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        manager: PaywallManager,
        configuration: PaywallConfiguration = PaywallConfiguration(),
        defaultSelected: ProductType? = nil,
        onClose: (() -> Void)? = nil,
        onPurchaseSuccess: (() -> Void)? = nil,
        onPurchaseFailure: ((String) -> Void)? = nil
    ) {
        self.manager = manager
        self.configuration = configuration
        self.onClose = onClose
        self.onPurchaseSuccess = onPurchaseSuccess
        self.onPurchaseFailure = onPurchaseFailure
        self._selectedProduct = State(initialValue: defaultSelected ?? configuration.products.first ?? .yearly)
        self._closeButtonTimeRemaining = State(initialValue: configuration.closeButtonDelay)
    }
    
    @State private var prices = ["$6.99", "$69.99", "$199.99"]

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content
                .onAppear {
                    manager.fetchOfferings()
                }
                .onReceive(timer) { _ in
                    if remoteConfigHideCloseButton {
                        guard closeButtonTimeRemaining > 0 else {
                            if !showCloseButton {
                                withAnimation { showCloseButton = true }
                            }
                            return
                        }
                        closeButtonTimeRemaining -= 1
                    } else {
                        withAnimation { showCloseButton = true }
                    }
                }
        }
        .overlay {
            if manager.isPurchasing {
                loadingOverlay
            }
        }
        .onChange(of: manager.purchaseError) { newError in
            if let e = newError {
                onPurchaseFailure?(e)
            }
        }
        .onChange(of: manager.isSubscriptionActive) { active in
            if active { onPurchaseSuccess?() }
        }
    }
}

private extension PaywallView {
    var content: some View {
        ZStack(alignment: .top) {
            VStack {
                Spacer()
                VStack(spacing: 10) {
                    header
                    features
                    productList
                    cancelAnytime
                    purchaseButton
                    footer
                }
                .padding(.horizontal, 16)
            }
            if showCloseButton {
                closeButton
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    var header: some View {
        VStack(spacing: 4) {
            Text(configuration.title)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            Text(configuration.subtitle)
                .foregroundColor(.white.opacity(0.75))
                .font(.body)
                .bold()
        }
        .padding(.bottom)
    }

    var features: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(configuration.featureListFor(selectedProduct), id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(feature)
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.white)
            }
        }.padding(.bottom, 6)
    }

    var productList: some View {
        VStack(spacing: 12) {
            ForEach(configuration.products, id: \.self) { product in
                productRow(for: product)
            }
        }.padding(.vertical, 6)
    }

    func productRow(for product: ProductType) -> some View {
        let isSelected = product == selectedProduct
        return HStack {
            Image(systemName: isSelected ? "circle.circle.fill" : "circle")
                .resizable()
                .frame(width: 22, height: 22)
                .opacity(isSelected ? 1 : 0.4)
                .padding(.leading, 4)
            Text(product.displayTitle)
                .font(.system(size: 16, weight: .semibold))
                .padding(.leading, 6)
            Spacer()
            ///TODO: Check later
            Text(manager.offerings?.current?.availablePackages[product.packageIndex].storeProduct.localizedPriceString ?? prices[product.packageIndex])
                .font(.system(size: 16))
        }
        .padding()
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isSelected ? 0.06 : 0.03))
                .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(configuration.accentColor.opacity(isSelected ? 1 : 0.3), lineWidth: 1.5))
        )
        .foregroundColor(.white)
        .onTapGesture {
            withAnimation { selectedProduct = product }
        }
    }

    var cancelAnytime: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
            Text("Cancel Anytime")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.vertical, 4)
    }

    var purchaseButton: some View {
        Button(action: buySelected) {
            ZStack {
                RoundedRectangle(cornerRadius: 999)
                    .fill(.white)
                    .frame(height: 56)
                    .shadow(color: configuration.accentColor.opacity(0.18), radius: 12, x: 2, y: 4)
                Text(manager.isPurchasing ? "Please wait..." : "Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
        }
        .disabled(manager.isPurchasing)
        .padding(.vertical, 8)
    }

    var footer: some View {
        HStack(spacing: 12) {
            Button("Terms of Use") {
                UIApplication.shared.open(configuration.termsAndConditions)
            }
            Text("|")
                .foregroundColor(.white.opacity(0.5))
            Button("Privacy Policy") {
                UIApplication.shared.open(configuration.privacyPolicy)
            }
            Text("|")
                .foregroundColor(.white.opacity(0.5))
            Button("Restore Purchase") {
                manager.restorePurchases { _ in }
            }
        }
        .font(.system(size: 13, weight: .light))
        .foregroundColor(.white)
        .padding(.top, 6)
    }

    var closeButton: some View {
        HStack {
            Button(action: {
                onClose?()
            }) {
                ZStack {
                    Circle().fill(Color.white)
                        .frame(width: 25, height: 25)
                    Image(systemName: "xmark")
                        .font(.footnote)
                        .foregroundColor(.black)
                }
            }
            Spacer()
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
}

private extension PaywallView {
    func buySelected() {
        var selectedPackage: Package? = nil

        if let offerings = manager.offerings {
            if let pid = configuration.productIdentifiers[selectedProduct] {
                for offering in offerings.all.values {
                    for package in offering.availablePackages {
                        if package.storeProduct.productIdentifier == pid {
                            selectedPackage = package
                            break
                        }
                    }
                    if selectedPackage != nil { break }
                }
            }
            if selectedPackage == nil {
                selectedPackage = offerings.current?.availablePackages.first
            }
        }

        manager.purchase(package: selectedPackage, productIdentifier: configuration.productIdentifiers[selectedProduct]) { success in
            if success {
                onPurchaseSuccess?()
            } else {
                if let error = manager.purchaseError {
                    onPurchaseFailure?(error)
                }
            }
        }
    }
}

