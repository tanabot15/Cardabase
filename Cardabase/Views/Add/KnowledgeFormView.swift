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
    
    enum Field {
        case title
        case summary
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var customFields: [FieldValue] = []
    @State private var isKeepAddingMode: Bool = false
    
    // OCR Camera Scanner State
    @State private var isShowingOCRScanner: Bool = false
    @State private var targetFieldForOCR: Field = .title
    
    private var isEditing: Bool {
        knowledgeToEdit != nil
    }
    
    private var isSaveDisabled: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let knowledge = knowledgeToEdit {
            return trimmedTitle.isEmpty || trimmedSummary.isEmpty ||
            (title == knowledge.title && summary == knowledge.summary && customFields == initialCustomFields(for: knowledge))
        } else {
            return trimmedTitle.isEmpty || trimmedSummary.isEmpty
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                    HStack {
                        TextField("Title", text: $title)
                            .focused($focusedField, equals: .title)
                        
                        Button(action: {
                            targetFieldForOCR = .title
                            isShowingOCRScanner = true
                        }) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Summary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: {
                                targetFieldForOCR = .summary
                                isShowingOCRScanner = true
                            }) {
                                HStack(spacing: 2) {
                                    Image(systemName: "camera.viewfinder")
                                    Text("Scan")
                                }
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        
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
            .sheet(isPresented: $isShowingOCRScanner) {
                TextScannerView { recognizedText in
                    if targetFieldForOCR == .title {
                        self.title = recognizedText
                    } else {
                        if self.summary.isEmpty {
                            self.summary = recognizedText
                        } else {
                            self.summary += "\n\(recognizedText)"
                        }
                    }
                }
            }
            .onAppear {
                setupInitialValues()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .title
                }
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
                resetFormFields()
                focusedField = .title
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Previews
#Preview("New Record Form Preview") {
    let folder = Folder(name: "SAKE DIPLOMA Exam")
    return KnowledgeFormView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
