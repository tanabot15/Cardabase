//
//  KnowledgeFormView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct KnowledgeFormView: View {
    @Environment(\.modelContext) private var modelConetxt
    @Environment(\.dismiss) private var dismiss
    
    let folder: Folder
    var knowledgeToEdit: Knowledge?
    
    // State management
    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var customFields: [FieldValue] = []
    
    // for adding custom fields
    @State private var newFieldKey: String = ""
    @State private var newFieldValue: String = ""
    @State private var newFieldType: FieldType = .text
    
    private var isEditing: Bool {
        knowledgeToEdit != nil
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
                
                // moving custom field
                Section(header: Text("Custom Fields (\(customFields.count))")) {
                    if customFields.isEmpty {
                        Text("No custom fields added.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($customFields) { $field in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading) {
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
                        .onDelete(perform: deleteCustomField)
                    }
                }
                
                Section(header: Text("Add Custom Field")) {
                    TextField("Field Key (e.g. Year, URL, Tag)", text: $newFieldKey)
                    TextField("Value", text: $newFieldValue)
                    
                    Picker("Field Type", selection: $newFieldType) {
                        ForEach(FieldType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Button(action: addCustomField) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Field")
                        }
                        .font(.subheadline)
                        .bold()
                    }
                    .disabled(newFieldKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialValues() {
        if let knowledge = knowledgeToEdit {
            title = knowledge.title
            summary = knowledge.summary
            customFields = knowledge.customFields
        }
    }
    
    private func addCustomField() {
        let trimmedKey = newFieldKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        
        let field = FieldValue(
            key: trimmedKey,
            value: newFieldValue.trimmingCharacters(in: .whitespacesAndNewlines),
            type: newFieldType
        )
        customFields.append(field)
        
        newFieldKey = ""
        newFieldValue = ""
        newFieldType = .text
    }
    
    private func deleteCustomField(at offsets: IndexSet) {
        customFields.remove(atOffsets: offsets)
    }
    
    private func saveKnowledge() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        if let knowledge = knowledgeToEdit {
            knowledge.title = trimmedTitle
            knowledge.summary = summary
            knowledge.customFields = customFields
            knowledge.updatedAt = Date()
        } else {
            let knowledge = Knowledge(
                title: trimmedTitle,
                summary: summary,
                customFields: customFields
            )
            knowledge.folder = folder
            folder.knowledges.append(knowledge)
        }
        
        dismiss()
    }
}

#Preview {
    let folder = Folder(name: "Sample Folder")
    return KnowledgeFormView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
