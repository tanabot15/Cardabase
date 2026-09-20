//
//  Knowledge.swift
//  Cardabase
//

import Foundation
import SwiftData
import SwiftUI

/// Learning review status for flashcard items.
enum MasterStatus: String, Codable, CaseIterable {
    case unreviewed = "unreviewed"
    case mastered = "mastered"
    case incorrect = "incorrect"
    
    var displayName: String {
        switch self {
        case .unreviewed: return "Unreviewed"
        case .mastered: return "Mastered"
        case .incorrect: return "Needs Review"
        }
    }
}

/// SwiftData entity representing an individual record within a database.
@Model
final class Knowledge {
    var id: UUID
    var title: String
    var summary: String
    var createdAt: Date
    var updatedAt: Date
    
    // Custom values for custom fields
    var customFields: [FieldValue]
    
    // Study and review tracking metrics
    var reviewCount: Int
    var correctCount: Int
    var masterStatus: MasterStatus
    var lastReviewedAt: Date?
    
    // Associated folder database
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
        masterStatus: MasterStatus = .unreviewed,
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
        self.masterStatus = masterStatus
        self.lastReviewedAt = lastReviewedAt
    }
    
    /// Calculated percentage rate of correct review attempts.
    var accuracyRate: Double {
        guard reviewCount > 0 else { return 0.0 }
        return (Double(correctCount) / Double(reviewCount)) * 100
    }
    
    /// Helper to dynamically retrieve value by field name key.
    func value(forKey key: String) -> String? {
        if key == "Title" { return title }
        if key == "Summary" { return summary }
        return customFields.first(where: { $0.key == key })?.value
    }
}

// MARK: - Preview
#Preview("Knowledge Record Preview") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    
    let item = Knowledge(
        title: "PER (Price to Earnings Ratio)",
        summary: "Measures current share price relative to its per-share earnings.",
        customFields: [
            FieldValue(key: "Formula", value: "Share Price / EPS", type: .text),
            FieldValue(key: "Benchmark", value: "15x - 20x", type: .text)
        ],
        reviewCount: 5,
        correctCount: 4,
        masterStatus: .mastered
    )
    container.mainContext.insert(item)
    
    return NavigationStack {
        List {
            Section(header: Text("Record Details")) {
                Text(item.title).font(.title2).bold()
                Text(item.summary).foregroundStyle(.secondary)
            }
            
            Section(header: Text("Custom Attributes")) {
                ForEach(item.customFields) { field in
                    LabeledContent(field.key, value: field.value)
                }
            }
            
            Section(header: Text("Study Progress")) {
                LabeledContent("Status", value: item.masterStatus.displayName)
                LabeledContent("Accuracy Rate", value: String(format: "%.1f%%", item.accuracyRate))
            }
        }
        .navigationTitle("Record View")
    }
    .modelContainer(container)
}
