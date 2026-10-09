//
//  FolderFormView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct FolderFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var parentFolder: Folder?
    
    // MARK: - Form State
    @State private var newFolderName: String = ""
    @State private var customSchemas: [FieldSchema] = []
    
    // Custom field creation states
    @State private var newSchemaKey: String = ""
    @State private var newSchemaType: FieldType = .text
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database Name")) {
                    TextField("e.g. Finance, AI Concepts", text: $newFolderName)
                }
                
                Section(header: Text("Custom Field Schemas (\(customSchemas.count))")) {
                    if customSchemas.isEmpty {
                        Text("No custom fields added.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(customSchemas) { schema in
                            HStack {
                                Text(schema.key)
                                    .font(.subheadline)
                                Spacer()
                                Text(schema.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { customSchemas.remove(atOffsets: $0) }
                    }
                }
                
                Section(header: Text("Add Custom Field")) {
                    TextField("Field Key (e.g. Region, Variety, Year)", text: $newSchemaKey)
                    Picker("Field Type", selection: $newSchemaType) {
                        ForEach(FieldType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Button(action: addSchema) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Field")
                        }
                        .font(.subheadline)
                        .bold()
                    }
                    .disabled(newSchemaKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("New Database")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNewFolder()
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addSchema() {
        let trimmedKey = newSchemaKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        customSchemas.append(FieldSchema(key: trimmedKey, type: newSchemaType))
        newSchemaKey = ""
        newSchemaType = .text
    }
    
    private func createNewFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let folder = Folder(name: trimmedName, customFieldSchemas: customSchemas)
        if let parentFolder = parentFolder {
            folder.parent = parentFolder
            parentFolder.subfolders.append(folder)
        } else {
            modelContext.insert(folder)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("Folder Form Preview") {
    FolderFormView()
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
