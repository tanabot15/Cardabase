//
//  Folder.swift
//  Cardabase
//

import Foundation
import SwiftData
import SwiftUI

/// SwiftData entity representing a database folder with custom schemas.
@Model
final class Folder {
    var id: UUID
    var name: String
    var createdAt: Date
    
    // Default flashcard card keys
    var defaultFrontKey: String
    var defaultBackKey: String
    
    // Custom field schemas defined at the database level
    var customFieldSchemas: [FieldSchema]
    
    // Subfolders hierarchy
    @Relationship(deleteRule: .cascade, inverse: \Folder.parent)
    var subfolders: [Folder]
    
    // Parent folder
    var parent: Folder?
    
    // Child records in this folder
    @Relationship(deleteRule: .cascade, inverse: \Knowledge.folder)
    var knowledges: [Knowledge]
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        defaultFrontKey: String = "Title",
        defaultBackKey: String = "Summary",
        customFieldSchemas: [FieldSchema] = [],
        subfolders: [Folder] = [],
        knowledges: [Knowledge] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.defaultFrontKey = defaultFrontKey
        self.defaultBackKey = defaultBackKey
        self.customFieldSchemas = customFieldSchemas
        self.subfolders = subfolders
        self.knowledges = knowledges
    }
    
    /// Returns all available field keys including built-in and custom fields.
    var availableFieldKeys: [String] {
        var keys: Set<String> = ["Title", "Summary"]
        for schema in customFieldSchemas {
            keys.insert(schema.key)
        }
        return Array(keys).sorted()
    }
}

// MARK: - Preview
#Preview("Folder Preview") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    
    let folder = Folder(
        name: "Financial Indicators",
        customFieldSchemas: [
            FieldSchema(key: "Formula", type: .text),
            FieldSchema(key: "Benchmark", type: .text)
        ]
    )
    container.mainContext.insert(folder)
    
    return NavigationStack {
        List {
            Section(header: Text("Database Details")) {
                LabeledContent("Name", value: folder.name)
                LabeledContent("Created", value: folder.createdAt.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Custom Schemas", value: "\(folder.customFieldSchemas.count) fields")
            }
        }
        .navigationTitle("Folder Overview")
    }
    .modelContainer(container)
}
