//
//  FolderListView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct FolderListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    var parentFolder: Folder?

    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \Folder.createdAt, order: .reverse)
    private var rootFolders: [Folder]
    
    // MARK: - State Management
    @State private var searchText: String = ""
    @State private var isShowingCreateSheet: Bool = false
    @State private var newFolderName: String = ""
    @State private var customSchemas: [FieldSchema] = []
    
    // States for custom field creation
    @State private var newSchemaKey: String = ""
    @State private var newSchemaType: FieldType = .text
    
    private var displayedFolders: [Folder] {
        let sourceFolders = parentFolder?.subfolders ?? rootFolders
        if searchText.isEmpty {
            return sourceFolders
        } else {
            return sourceFolders.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if !appState.isProUser {
                    AdBannerView()
                }
                
                List {
                    if displayedFolders.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Databases Yet" : "No Results",
                            systemImage: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                            description: Text(searchText.isEmpty ? "Tap '+' button to create your first database." : "Try searching for another name.")
                        )
                    } else {
                        ForEach(displayedFolders) { folder in
                            FolderRowView(folder: folder)
                        }
                        .onDelete(perform: deleteFolders)
                    }
                }
            }
            
            // Floating Add Button
            Button(action: handleAddFolderTapped) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Databases")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isShowingCreateSheet) {
            createFolderSheet
        }
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Subviews
    
    private var createFolderSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database Name")) {
                    TextField("e.g. SAKE DIPLOMA, Finance, AI Concepts", text: $newFolderName)
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
                    Button("Cancel") { resetCreateSheet() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createNewFolder() }
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
    
    private func handleAddFolderTapped() {
        if Limits.isFolderLimitReached(currentCount: rootFolders.count, isPro: appState.isProUser) {
            appState.isShowingPaywall = true
        } else {
            isShowingCreateSheet = true
        }
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
        
        resetCreateSheet()
    }
    
    private func resetCreateSheet() {
        newFolderName = ""
        customSchemas = []
        newSchemaKey = ""
        newSchemaType = .text
        isShowingCreateSheet = false
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            let folder = displayedFolders[index]
            modelContext.delete(folder)
        }
    }
}

// MARK: - Subview: Folder Row Component

private struct FolderRowView: View {
    let folder: Folder
    
    @State private var isShowingDatabase: Bool = false
    @State private var isShowingCardConfig: Bool = false
    
    private var recordCount: Int {
        folder.knowledges.count
    }
    
    private var masteryPercentage: Int {
        guard recordCount > 0 else { return 0 }
        let masteredCount = folder.knowledges.filter { $0.masterStatus == .mastered }.count
        return Int(round(Double(masteredCount) / Double(recordCount) * 100))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    Text("\(recordCount) records")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if recordCount > 0 {
                        Text("\(masteryPercentage)% mastered")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(masteryPercentage == 100 ? .green : .secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // 1. DatebaseView
                Button(action: {
                    isShowingDatabase = true
                }) {
                    Image(systemName: "cylinder.split.1x2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                
                // 2. FlashCardView
                Button(action: {
                    isShowingCardConfig = true
                }) {
                    Image(systemName: "rectangle.on.rectangle.angled.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                        .padding(10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .navigationDestination(isPresented: $isShowingDatabase) {
            DatabaseView(folder: folder)
        }
        .navigationDestination(isPresented: $isShowingCardConfig) {
            CardConfigView(folder: folder)
        }
    }
}

// MARK: - Previews
#Preview("Folder List") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA Study")
    folder1.knowledges.append(Knowledge(title: "Goshiki", summary: "Five basic sake taste elements"))
    
    let folder2 = Folder(name: "Financial Indicators")
    folder2.knowledges.append(contentsOf: [
        Knowledge(title: "ROIC", summary: "Return on Invested Capital"),
        Knowledge(title: "PER", summary: "Price to Earnings Ratio")
    ])
    
    context.insert(folder1)
    context.insert(folder2)
    
    return NavigationStack {
        FolderListView()
    }
    .modelContainer(container)
    .environmentObject(AppState())
}
