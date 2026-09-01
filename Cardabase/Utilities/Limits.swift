//
//  Limits.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation

struct Limits {
    // Pro Product Identifier
    static let proProductID: String = "com.cardabase.pro"
    
    // Limits for Free Tier
    static let maxFoldersForFree: Int = 3
    static let maxKnowledgesPerFolderForFree: Int = 50
    
    // Free version limit checks
    static func isFolderLimitReached(currentCount: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCount >= maxFoldersForFree
    }
    
    static func isKnowledgeLimitReached(currentCountInFolder: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCountInFolder >= maxKnowledgesPerFolderForFree
    }
}
