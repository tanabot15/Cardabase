//
//  FieldValue.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation

public enum FieldType: String, Codable, CaseIterable, Identifiable {
    case text
    case number
    case url
    case tag
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .url: return "URL"
        case .tag: return "Tag"
        }
    }
}

public struct FieldValue: Codable, Hashable, Identifiable {
    public var id: UUID
    public var key: String
    public var value: String
    public var type: FieldType
    
    public init(id: UUID = UUID(), key: String, value: String, type: FieldType = .text) {
        self.id = id
        self.key = key
        self.value = value
        self.type = type
    }
}
