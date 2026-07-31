//
//  FieldValue.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation

enum FieldType: String, Codable, CaseIterable, Identifiable {
    case text
    case number
    case url
    case tag
    
    var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .url: return "URL"
        case .tag: return "Tag"
        }
    }
}

struct FieldValue: Codable, Hashable, Identifiable {
    let id: UUID
    var key: String
    var value: String
    var type: FieldType
    
    init(id: UUID = UUID(), key: String, value: String, type: FieldType = .text) {
        self.id = id
        self.key = key
        self.value = value
        self.type = type
    }
}
