//
//  PaywallConfiguration.swift
//  BKPaywallKit
//
//  Created by Baturay Koc on 30.01.26.
//

import SwiftUI

public struct PaywallConfiguration {
    public var title: String
    public var subtitle: String
    public var accentColor: Color
    public var products: [ProductType]
    public var featureListFor: (ProductType) -> [String]
    public var productIdentifiers: [ProductType: String]
    public var closeButtonDelay: Int
    public var termsAndConditions: URL
    public var privacyPolicy: URL

    public init(
        title: String = "Pro",
        subtitle: String = "Unlock All Features with Pro",
        accentColor: Color = Color(red: 175/255, green: 243/255, blue: 31/255),
        products: [ProductType] = [.yearly, .weekly],
        featureListFor: @escaping (ProductType) -> [String] = { product in
            switch product {
            case .weekly: return ["Powered by ****", "Full Access to All Features", "350 Credits Weekly"]
            case .yearly: return ["Powered by ****", "Full Access to All Features", "3000 Credits Yearly"]
            case .lifetime: return ["Powered by ****", "Full Access to All Features", "Unlimited Credits"]
            }
        },
        productIdentifiers: [ProductType: String] = [:],
        closeButtonDelay: Int = 5,
        termsAndConditions: URL = URL(string: "https://example.com/terms")!,
        privacyPolicy: URL = URL(string: "https://example.com/privacy")!
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.products = products
        self.featureListFor = featureListFor
        self.productIdentifiers = productIdentifiers
        self.closeButtonDelay = closeButtonDelay
        self.termsAndConditions = termsAndConditions
        self.privacyPolicy = privacyPolicy
    }
}
