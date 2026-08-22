//
//  FolderListView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct FolderListView: View {
    @Environment(\.modelContext) private var modelContext
    
    var mode: ViewMode = .database
    var parentFolder: Folder?

    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \Folder.createdAt, order: .reverse)
    private var rootFolders: [Folder]
    
    // state management
    @State private var searchText: String = ""
    @State private var isShowingCreaateSheet: Bool = false
    @State private var newFolderName: String = ""
//    @State private var isShowingPaywall: Bool = false
    
    // folder list
    private var displayedFolders: [Folder] {
        let sourceFolders = parentFolder?.subfolders ?? rootFolders
        if searchText.isEmpty {
            return sourceFolders
        } else {
            return sourceFolders.filter { $0.name.localizedCaseInsensitiveContains(searchText)}
        }
    }
    
    // MARK: - Main view
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                AdBannerView()
                
                List {
                    if displayedFolders.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Databases Yet" : "No Results",
                            systemImage: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                            description: Text(searchText.isEmpty ? "Tap the '+' button to create your first database." : "Try searching for a different name.")
                        )
                    } else {
                        ForEach(displayedFolders) { folder in
                            NavigationLink {
                                if mode == .database {
                                    DatabaseView(folder: folder)
                                } else {
                                    CardConfigView(folder: folder)
                                }
                            } label: {
                                FolderRowView(folder: folder, mode: mode)
                            }
                        }
                        .onDelete(perform: deleteFolders)
                    }
                }
            }
            
            if mode == .database {
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
        }
        .navigationTitle(
            parentFolder?.name ?? (mode == .database ? "Databases" : "Flashcards")
        )
        .navigationBarTitleDisplayMode(.inline)
        .searchableIf(mode == .database, text: $searchText, prompt: "Search databases...")
        .sheet(isPresented: $isShowingCreaateSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Database Name")) {
                        TextField("e.g. AI Concepts, Patents, Finance", text: $newFolderName)
                    }
                }
                .navigationTitle("New Database")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingCreaateSheet = false
                            newFolderName = ""
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
            .presentationDetents([.height(200)])
        }
        // for Pro
//        .sheet(isPresented: $isShowingPaywall) {
//            PaywallView()
//        }
    }
    
    // MARK: - Actions
    private func handleAddFolderTapped() {
        // for Pro
//        let totalFolderCount = (try? modelContext.fetchCount(FetchDescriptor<Folder>())) ?? 0
//        
//        if Limits.isFolderLimitReached(currentCount: totalFolderCount) {
//            isShowingPaywall = true
//        } else {
//            isShowingCreaateSheet = true
//        }
        
        // delete when Pro
        isShowingCreaateSheet = true
    }
    
    private func createNewFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let folder = Folder(name: trimmedName)
        if let parentFolder = parentFolder {
            folder.parent = parentFolder
            parentFolder.subfolders.append(folder)
        } else {
            modelContext.insert(folder)
        }
        
        newFolderName = ""
        isShowingCreaateSheet = false
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            let folder = displayedFolders[index]
            modelContext.delete(folder)
        }
    }
}

// MARK: - Conditional Searchable Extension
private extension View {
    @ViewBuilder
    func searchableIf(_ condition: Bool, text: Binding<String>, prompt: String) -> some View {
        if condition {
            self.searchable(text: text, prompt: prompt)
        } else {
            self
        }
    }
}

// MARK: - Folder Row Component
private struct FolderRowView: View {
    let folder: Folder
    let mode: ViewMode
    
    private var recordCount: Int {
        folder.knowledges.count
    }
    
    private var masteryPercentage: Int {
        guard recordCount > 0 else { return 0 }
        let masteredCount = folder.knowledges.filter { $0.masterStatus == .mastered }.count
        return Int(round(Double(masteredCount) / Double(recordCount) * 100))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: mode == .database ? "cylinder.split.1x2.fill" : "rectangle.stack.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            
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
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Temporary Placeholders
//private struct DatabasePlaceholderView: View {
//    let folder: Folder
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "shippingbox.fill")
//                .font(.system(size: 50))
//                .foregroundStyle(.secondary)
//            Text("Database View for '\(folder.name)'")
//                .font(.title3)
//                .bold()
//            Text("Knowledge records will be listed here.")
//                .foregroundStyle(.secondary)
//        }
//        .navigationTitle(folder.name)
//    }
//}
//
//private struct PaywallPlaceholderView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "star.circle.fill")
//                .font(.system(size: 60))
//                .foregroundStyle(.yellow)
//            Text("Upgrade to Cardabase Pro")
//                .font(.title2)
//                .bold()
//            Text("Free version is limited to 3 databases.\nUpgrade to Pro for unlimited databases & records.")
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.secondary)
//                .padding(.horizontal)
//            
//            Button(action: { dismiss() }) {
//                Text("Close")
//                    .bold()
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.accentColor)
//                    .foregroundStyle(.white)
//                    .cornerRadius(12)
//            }
//            .padding(.horizontal, 12)
//        }
//        .padding()
//    }
//}

#Preview("Databases") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "AI & Tech Concepts")
    folder1.knowledges.append(Knowledge(title: "Attention Mechanism", summary: "Calculates dynamic weights"))
    
    let folder2 = Folder(name: "Financial Indicators")
    folder2.knowledges.append(contentsOf: [
        Knowledge(title: "ROIC", summary: "Return on Invested Capital"),
        Knowledge(title: "PER", summary: "Price to Earnings Ratio"),
        Knowledge(title: "ROE", summary: "Return on Equity")
    ])
    
    let folder3 = Folder(name: "Intellectual Property")
    
    context.insert(folder1)
    context.insert(folder2)
    context.insert(folder3)
    
    return NavigationStack {
        FolderListView(mode: .database)
    }
    .modelContainer(container)
}

#Preview("Flashcards") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "Financial Indicators")
    let k1 = Knowledge(title: "ROIC", summary: "Return on Invested Capital")
    k1.masterStatus = .mastered // 修正
    folder1.knowledges.append(contentsOf: [k1, Knowledge(title: "PER", summary: "Price to Earnings Ratio")])
    
    context.insert(folder1)
    
    return NavigationStack {
        FolderListView(mode: .flashcards)
    }
    .modelContainer(container)
}
