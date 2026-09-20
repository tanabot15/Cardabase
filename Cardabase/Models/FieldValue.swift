//
//  FieldValue.swift
//  Cardabase
//

import SwiftUI

/// Supported data types for database custom fields.
enum FieldType: String, Codable, CaseIterable, Identifiable {
    case text
    case number
    case url
    case tag
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .number: return "Number"
        case .url: return "URL"
        case .tag: return "Tag"
        }
    }
}

/// Key-value pair container for dynamic custom record attributes.
struct FieldValue: Codable, Hashable, Identifiable {
    var id: UUID
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

/// Schema definition for database-level custom fields.
struct FieldSchema: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var key: String
    var type: FieldType
}

// MARK: - Preview Helper View
private struct FieldValuePreviewView: View {
    let sampleFields: [FieldValue] = [
        FieldValue(key: "Formula", value: "Share Price / EPS", type: .text),
        FieldValue(key: "Benchmark", value: "15x - 20x", type: .text),
        FieldValue(key: "Tag", value: "Valuation", type: .tag)
    ]
    
    var body: some View {
        List(sampleFields) { field in
            HStack {
                Text(field.key)
                    .font(.headline)
                Spacer()
                Text(field.value)
                    .foregroundStyle(.secondary)
                Text(field.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

#Preview("Field Values") {
    FieldValuePreviewView()
}
