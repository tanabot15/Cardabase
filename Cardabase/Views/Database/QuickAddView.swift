//
//  QuickAddView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folder: Folder
    
    @State private var rawText: String = ""
    @State private var parsedItems: [ParsedRecord] = []
    
    struct ParsedRecord: Identifiable {
        let id = UUID()
        var title: String
        var summary: String
        var customFields: [FieldValue]
    }
    
    private var isSaveDisabled: Bool {
        parsedItems.isEmpty || Limits.isKnowledgeLimitReached(currentCountInFolder: folder.knowledges.count + parsedItems.count, isPro: appState.isProUser)
    }
    
    /// Constructs field schema structure string (e.g. "Title, Summary, (Formula), (Benchmark)")
    private var fieldStructurePreview: String {
        var fields = ["Title", "Summary"]
        let customFieldsFormatted = folder.customFieldSchemas.map { "(\($0.key))" }
        fields.append(contentsOf: customFieldsFormatted)
        return fields.joined(separator: ", ")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Guideline Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Expected Import Format")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Column Order:")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text(fieldStructurePreview)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Input Section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Paste Text / List")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !rawText.isEmpty {
                            Button("Clear") {
                                rawText = ""
                                parseText()
                            }
                            .font(.caption)
                        }
                    }
                    
                    TextEditor(text: $rawText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .onChange(of: rawText) { _, _ in
                            parseText()
                        }
                    
                    Text("Supported delimiters: Tab (Excel/Sheets), Comma, or Colon. Each line creates one card.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                
                // Preview Section
                List {
                    Section(header: Text("Preview Parsed Cards (\(parsedItems.count))")) {
                        if parsedItems.isEmpty {
                            ContentUnavailableView(
                                "No Cards Parsed",
                                systemImage: "doc.text.magnifyingglass",
                                description: Text("Paste list items above to automatically convert them into cards.")
                            )
                        } else {
                            ForEach(Array(parsedItems.enumerated()), id: \.element.id) { index, item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.secondary)
                                        Text(item.title)
                                            .font(.headline)
                                    }
                                    
                                    if !item.summary.isEmpty {
                                        Text(item.summary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    if !item.customFields.isEmpty {
                                        HStack(spacing: 6) {
                                            ForEach(item.customFields) { field in
                                                if !field.value.isEmpty {
                                                    Text("\(field.key): \(field.value)")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color(.tertiarySystemBackground))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        .padding(.top, 2)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Quick Add Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import (\(parsedItems.count))") {
                        saveAllCards()
                    }
                    .bold()
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
    
    // MARK: - Parsing Logic
    
    private func parseText() {
        let lines = rawText.components(separatedBy: .newlines)
        var results: [ParsedRecord] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            var components: [String] = []
            
            // 1. Tab separated (e.g. copied from Excel/Spreadsheets)
            if trimmedLine.contains("\t") {
                components = trimmedLine.components(separatedBy: "\t")
            }
            // 2. Comma separated
            else if trimmedLine.contains(",") {
                components = trimmedLine.components(separatedBy: ",")
            }
            // 3. Colon separated
            else if trimmedLine.contains(":") {
                components = trimmedLine.components(separatedBy: ":")
            }
            // 4. Single text line
            else {
                components = [trimmedLine]
            }
            
            components = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            let cardTitle = components.indices.contains(0) ? components[0] : ""
            let cardSummary = components.indices.contains(1) ? components[1] : ""
            
            guard !cardTitle.isEmpty else { continue }
            
            // Map remaining components to database custom fields
            var cardCustomFields: [FieldValue] = []
            let schemas = folder.customFieldSchemas
            
            for (index, schema) in schemas.enumerated() {
                let compIndex = index + 2 // After Title and Summary
                let value = components.indices.contains(compIndex) ? components[compIndex] : ""
                cardCustomFields.append(FieldValue(key: schema.key, value: value, type: schema.type))
            }
            
            results.append(ParsedRecord(title: cardTitle, summary: cardSummary, customFields: cardCustomFields))
        }
        
        self.parsedItems = results
    }
    
    // MARK: - Save Logic
    
    private func saveAllCards() {
        for item in parsedItems {
            let knowledge = Knowledge(
                title: item.title,
                summary: item.summary,
                customFields: item.customFields
            )
            knowledge.folder = folder
            folder.knowledges.append(knowledge)
        }
        
        dismiss()
    }
}

// MARK: - Previews

#Preview("Quick Add") {
    let folder = Folder(
        name: "Financial Terms",
        customFieldSchemas: [
            FieldSchema(key: "Formula", type: .text),
            FieldSchema(key: "Benchmark", type: .text)
        ]
    )
    
    return QuickAddView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
        .environmentObject(AppState())
}
