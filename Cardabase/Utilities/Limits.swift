//
//  Limits.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation

struct Limits {
    static let maxFoldersForFree: Int = 3
    static let maxKnowledgesPerFolderForFree: Int = 50
    
    // Free version check
    static func isFolderLimitReached(currentCount: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCount >= maxFoldersForFree
    }
    
    static func isKnowledgeLimitReached(currentCountInFolder: Int, isPro: Bool = false) -> Bool {
        if isPro { return false }
        return currentCountInFolder >= maxKnowledgesPerFolderForFree
    }
}
