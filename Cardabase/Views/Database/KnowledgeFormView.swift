//
//  KnowledgeFormView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct KnowledgeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let folder: Folder
    var knowledgeToEdit: Knowledge?
    
    // MARK: - Field Focus
    enum Field {
        case title
        case summary
    }
    
    @FocusState private var focusedField: Field?
    
    // MARK: - State Management
    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var customFields: [FieldValue] = []
    
    /// Keep Adding Mode Toggle State
    @State private var isKeepAddingMode: Bool = false
    
    private var isEditing: Bool {
        knowledgeToEdit != nil
    }
    
    private var isSaveDisabled: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let knowledge = knowledgeToEdit {
            let isTitleEmpty = trimmedTitle.isEmpty
            let isSummaryEmpty = trimmedSummary.isEmpty
            let isUnchanged = title == knowledge.title &&
                              summary == knowledge.summary &&
                              customFields == initialCustomFields(for: knowledge)
            
            return isTitleEmpty || isSummaryEmpty || isUnchanged
        } else {
            return trimmedTitle.isEmpty || trimmedSummary.isEmpty
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        NavigationStack {
            Form {
                // Keep Adding Toggle (Only for New Records)
                if !isEditing {
                    Section {
                        Toggle(isOn: $isKeepAddingMode) {
                            Label("Keep Adding Mode", systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    } footer: {
                        if isKeepAddingMode {
                            Text("Form will remain open after adding a record so you can quickly add the next one.")
                                .font(.caption2)
                        }
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $summary)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .summary)
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
                    Button(isKeepAddingMode && !isEditing ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : (isKeepAddingMode ? "Next" : "Add")) {
                        saveKnowledge()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear {
                setupInitialValues()
                // Auto focus Title field when presented
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .title
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
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
            resetFormFields()
        }
    }
    
    private func resetFormFields() {
        title = ""
        summary = ""
        customFields = folder.customFieldSchemas.map { schema in
            FieldValue(key: schema.key, value: "", type: schema.type)
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
            dismiss()
        } else {
            let knowledge = Knowledge(
                title: trimmedTitle,
                summary: trimmedSummary,
                customFields: customFields
            )
            knowledge.folder = folder
            folder.knowledges.append(knowledge)
            
            if isKeepAddingMode {
                // Keep form open for next card
                resetFormFields()
                focusedField = .title
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Previews

#Preview("New Record") {
    let folder = Folder(
        name: "Sample Folder",
        customFieldSchemas: [
            FieldSchema(key: "Category", type: .text),
            FieldSchema(key: "URL", type: .url)
        ]
    )
    
    return KnowledgeFormView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}

#Preview("Edit Record") {
    let folder = Folder(
        name: "Tech Companies",
        customFieldSchemas: [
            FieldSchema(key: "Category", type: .text),
            FieldSchema(key: "URL", type: .url)
        ]
    )
    
    let sampleKnowledge = Knowledge(
        title: "Apple Inc.",
        summary: "Multinational technology company headquartered in Cupertino, California.",
        customFields: [
            FieldValue(key: "Category", value: "Technology", type: .text),
            FieldValue(key: "URL", value: "https://apple.com", type: .url)
        ]
    )
    sampleKnowledge.folder = folder
    folder.knowledges.append(sampleKnowledge)
    
    return KnowledgeFormView(folder: folder, knowledgeToEdit: sampleKnowledge)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
