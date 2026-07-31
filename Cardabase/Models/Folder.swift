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
    
    // child folder
    @Relationship(deleteRule: .cascade, inverse: \Folder.parent)
    var subfolders: [Folder]
    
    // parent folder
    var parent: Folder?
    
    // knowledges included folder
    @Relationship(deleteRule: .cascade,inverse: \Knowledge.folder)
    var knowledges: [Knowledge]
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        defaultFrontKey: String = "Title",
        defaultBackKey: String = "Summary",
        subfolders: [Folder] = [],
        knowledges: [Knowledge] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.defaultFrontKey = defaultFrontKey
        self.defaultBackKey = defaultBackKey
        self.subfolders = subfolders
        self.knowledges = knowledges
    }
    
    var availableFieldKeys: [String] {
        var keys: Set<String> = ["Title", "Summary"]
        for knowledge in knowledges {
            for filed in knowledge.customFields {
                keys.insert(filed.key)
            }
        }
        return Array(keys).sorted()
    }
}
