//
//  KnowledgeFormView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct KnowledgeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let folder: Folder
    var knowledgeToEdit: Knowledge?
    
    // State management
    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var customFields: [FieldValue] = []
    
    private var isEditing: Bool {
        knowledgeToEdit != nil
    }
    
    // Disabled function
    private var isSaveDisabled: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let knowledge = knowledgeToEdit {
            // Edit Mode
            let isTitleEmpty = trimmedTitle.isEmpty
            let isSummaryEmpty = trimmedSummary.isEmpty
            let isUnchanged = title == knowledge.title &&
                              summary == knowledge.summary &&
                              customFields == initialCustomFields(for: knowledge)
            
            return isTitleEmpty || isSummaryEmpty || isUnchanged
        } else {
            // Add Mode
            return trimmedTitle.isEmpty || trimmedSummary.isEmpty
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Title (Front Card)", text: $title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary / Explanation (Back Card)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $summary)
                            .frame(minHeight: 100)
                    }
                }
                
                if !customFields.isEmpty {
                    Section(header: Text("Custom Fields")) {
                        ForEach($customFields) { $field in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(field.key)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("Value", text: $field.value)
                                }
                                Spacer()
                                Text(field.type.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(4)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Record" : "New Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveKnowledge()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func initialCustomFields(for knowledge: Knowledge) -> [FieldValue] {
        folder.customFieldSchemas.map { schema in
            if let existing = knowledge.customFields.first(where: { $0.key == schema.key }) {
                return existing
            } else {
                return FieldValue(key: schema.key, value: "", type: schema.type)
            }
        }
    }
    
    private func setupInitialValues() {
        if let knowledge = knowledgeToEdit {
            title = knowledge.title
            summary = knowledge.summary
            customFields = initialCustomFields(for: knowledge)
        } else {
            customFields = folder.customFieldSchemas.map { schema in
                FieldValue(key: schema.key, value: "", type: schema.type)
            }
        }
    }
    
    private func saveKnowledge() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty && !trimmedSummary.isEmpty else { return }
        
        if let knowledge = knowledgeToEdit {
            knowledge.title = trimmedTitle
            knowledge.summary = trimmedSummary
            knowledge.customFields = customFields
            knowledge.updatedAt = Date()
        } else {
            let knowledge = Knowledge(
                title: trimmedTitle,
                summary: trimmedSummary,
                customFields: customFields
            )
            knowledge.folder = folder
            folder.knowledges.append(knowledge)
        }
        
        dismiss()
    }
}

#Preview("New Record") {
    let folder = Folder(
        name: "Sample Folder",
        customFieldSchemas: [
            FieldSchema(key: "Category", type: .text),
            FieldSchema(key: "URL", type: .text)
        ]
    )
    
    KnowledgeFormView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}

#Preview("Edit Record") {
    let folder = Folder(
        name: "Sample Folder",
        customFieldSchemas: [
            FieldSchema(key: "Category", type: .text),
            FieldSchema(key: "URL", type: .text)
        ]
    )
    
    let sampleKnowledge = Knowledge(
        title: "Apple Inc.",
        summary: "An American multinational technology company headquartered in Cupertino, California.",
        customFields: [
            FieldValue(key: "Category", value: "Tech", type: .text),
            FieldValue(key: "URL", value: "https://apple.com", type: .text)
        ]
    )
    sampleKnowledge.folder = folder
    folder.knowledges.append(sampleKnowledge)
    
    return KnowledgeFormView(folder: folder, knowledgeToEdit: sampleKnowledge)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
