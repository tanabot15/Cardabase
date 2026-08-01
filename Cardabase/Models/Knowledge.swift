//
//  Knowledge.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation
import SwiftData

@Model
final class Knowledge {
    var id: UUID
    var title: String
    var summary: String
    var createdAt: Date
    var updatedAt: Date
    
    // custom fileds
    var customFields: [FieldValue]
    
    // learn status for flashcards
    var reviewCount: Int
    var correctCount: Int
    var isMastered: Bool
    var lastReviewedAt: Date?
    
    // related folder
    var folder: Folder?
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        customFields: [FieldValue] = [],
        reviewCount: Int = 0,
        correctCount: Int = 0,
        isMastered: Bool = false,
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customFields = customFields
        self.reviewCount = reviewCount
        self.correctCount = correctCount
        self.isMastered = isMastered
        self.lastReviewedAt = lastReviewedAt
    }
    
    var accuracyRate: Double {
        guard reviewCount > 0 else { return 0.0 }
        return (Double(correctCount) / Double(reviewCount)) * 100
    }
    
    func value(forKey key: String) -> String? {
        if key == "Title" { return title }
        if key == "Summary" { return summary }
        return customFields.first(where: { $0.key == key })?.value
    }
}
