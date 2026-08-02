//
//  Limits.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation

struct Limits {
    // for Pro
//    static let maxFoldersForFree: Int = 3
//    static let maxKnowledgesPerFolderForFree: Int = 50
    
    // Free version check
    static func isFolderLimitReached(currentCount: Int, isPro: Bool = false) -> Bool {
        // for Pro
//        if isPro { return false }
//        return currentCount >= maxFoldersForFree
        
        // delete for Pro
        return false
    }
    
    static func isKnowledgeLimitReached(currentCountInFolder: Int, isPro: Bool = false) -> Bool {
        // for Pro
//        if isPro { return false }
//        return currentCountInFolder >= maxKnowledgesPerFolderForFree
        
        // delete for Pro
        return false
    }
}
