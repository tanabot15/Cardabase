//
//  DatabaseView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct DatabaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var folder: Folder
    
    // state management
    @State private var searchText: String = ""
    @State private var isShowingAddSheet: Bool = false
    @State private var selectedKnowledgeToEdit: Knowledge?
    @State private var isShowingStudyConfig: Bool = false
    @State private var isShowingPaywall: Bool = false
    
    // search filtering record list
    private var filteredKnowledges: [Knowledge] {
        if searchText.isEmpty {
            return folder.knowledges.sorted { $0.createdAt > $1.createdAt }
        } else {
            return folder.knowledges.filter { knowledge in
                knowledge.title.localizedCaseInsensitiveContains(searchText) ||
                knowledge.summary.localizedCaseInsensitiveContains(searchText) ||
                knowledge.customFields.contains { $0.value.localizedCaseInsensitiveContains(searchText) }
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        List {
            if !folder.knowledges.isEmpty {
                Section {
                    Button(action: { isShowingStudyConfig = true }) {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start Flashcards")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(folder.knowledges.count) cards ready to study")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
                
            // record list
            Section(header: Text("Records (\(filteredKnowledges.count))")) {
                if filteredKnowledges.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Records" : "No Matching Records",
                        systemImage: searchText.isEmpty ? "doc.badge.plus" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Tap '+' to add your first knowledge record." : "Try a different search term.")
                    )
                } else {
                    ForEach(filteredKnowledges) { knowledge in
                        Button(action: { selectedKnowledgeToEdit = knowledge }) {
                            KnowledgeRowView(knowledge: knowledge)
                        }
                    }
                    .onDelete(perform: deleteKnowledges)
                }
            }
        }
        .navigationTitle(folder.name)
        .searchable(text: $searchText, prompt: "Search records & fields...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: handleAddKnowledgeTapped) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            KnowledgeFormView(folder: folder)
        }
        .sheet(item: $selectedKnowledgeToEdit) { knowledge in
            KnowledgeFormView(folder: folder, knowledgeToEdit: knowledge)
        }
        .sheet(isPresented: $isShowingStudyConfig) {
            CardConfigView(folder: folder)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallPlaceholderView()
        }
    }
    
    // MARK: - Actions
    private func handleAddKnowledgeTapped() {
        if Limits.isKnowledgeLimitReached(currentCountInFolder: folder.knowledges.count) {
            isShowingPaywall = true
        } else {
            isShowingAddSheet = true
        }
    }
    
    private func deleteKnowledges(at offsets: IndexSet) {
        for index in offsets {
            let knowledge = filteredKnowledges[index]
            modelContext.delete(knowledge)
        }
    }
}

// MARK: - Knowledge Row Component
private struct KnowledgeRowView: View {
    let knowledge: Knowledge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(knowledge.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if knowledge.isMastered {
                    Image(systemName: "checkmark.seel.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                }
            }
            
            if !knowledge.summary.isEmpty {
                Text(knowledge.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            if !knowledge.customFields.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(knowledge.customFields) { field in
                            HStack(spacing: 3) {
                                Text("\(field.key)")
                                    .fontWeight(.semibold)
                                Text(field.value)
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Temporary Placeholders
//private struct CardConfigPlaceholderView: View {
//    let folder: Folder
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                Image(systemName: "gearshape.2.fill")
//                    .font(.system(size: 60))
//                    .foregroundStyle(Color.accentColor)
//                Text("Card Config for '\(folder.name)'")
//                    .font(.title2)
//                    .bold()
//                Text("Front/Back column selector will be implemented here.")
//                    .foregroundStyle(.secondary)
//            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") { dismiss() }
//                }
//            }
//        }
//    }
//}

private struct PaywallPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            Text("Upgrade to Cardabase Pro")
                .font(.title2)
                .bold()
            Text("Free version is limited to 50 records per database.\nUpgrade to Pro for unlimited records.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("Close")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

#Preview {
    let folder = Folder(name: "Sample Database")
    folder.knowledges.append(Knowledge(title: "Sample Title", summary: "Sample Summary"))
    
    return NavigationStack {
        DatabaseView(folder: folder)
            .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
    }
}
