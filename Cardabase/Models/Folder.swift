//
//  Folder.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var createdAt: Date
    
    // default key
    var defaultFrontKey: String
    var defaultBackKey: String
    
    // Custom Field Schemas defined at Database level
    var customFieldSchemas: [FieldSchema]
    
    // child folder
    @Relationship(deleteRule: .cascade, inverse: \Folder.parent)
    var subfolders: [Folder]
    
    // parent folder
    var parent: Folder?
    
    // knowledges included folder
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
    
    var availableFieldKeys: [String] {
        var keys: Set<String> = ["Title", "Summary"]
        for schema in customFieldSchemas {
            keys.insert(schema.key)
        }
        return Array(keys).sorted()
    }
}
