//
//  Models.swift
//  BKPaywallKit
//
//  Created by Baturay Koc on 10/18/25.
//

import SwiftUI
import Foundation

public enum ProductType: String, CaseIterable, Codable {
    case weekly = "WEEKLY"
    case yearly = "YEARLY"
    case lifetime = "LIFETIME"

    public var displayTitle: String { rawValue }
    
    public var packageIndex: Int {
        switch self {
        case .weekly: return 0
        case .yearly: return 1
        case .lifetime: return 2
        }
    }
}
