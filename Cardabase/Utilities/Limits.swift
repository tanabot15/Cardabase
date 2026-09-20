//
//  Limits.swift
//  Cardabase
//

import Foundation

/// Centralized definitions for free-tier constraints and product identifiers.
struct Limits {
    /// In-App Purchase product ID for Pro upgrade
    static let proProductID: String = "com.cardabase.pro.v2"
    
    /// Limits applied to free tier users
    static let maxFoldersForFree: Int = 3
    static let maxKnowledgesPerFolderForFree: Int = 50
    
    /// Verifies if maximum allowed database limit is reached.
    static func isFolderLimitReached(currentCount: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCount >= maxFoldersForFree
    }
    
    /// Verifies if maximum allowed records limit per database is reached.
    static func isKnowledgeLimitReached(currentCountInFolder: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCountInFolder >= maxKnowledgesPerFolderForFree
    }
}
