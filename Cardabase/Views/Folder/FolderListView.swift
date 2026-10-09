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
    
    @State private var searchText: String = ""
    
    private var displayedFolders: [Folder] {
        let sourceFolders = parentFolder?.subfolders ?? rootFolders
        if searchText.isEmpty {
            return sourceFolders
        } else {
            return sourceFolders.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !appState.isProUser {
                AdBannerView()
            }
            
            List {
                if displayedFolders.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Databases Yet" : "No Results",
                        systemImage: searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Tap '+' on the tab bar to create your first database." : "Try searching for another name.")
                    )
                } else {
                    ForEach(displayedFolders) { folder in
                        FolderRowView(folder: folder)
                    }
                    .onDelete(perform: deleteFolders)
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Folders")
        .navigationBarTitleDisplayMode(.inline)
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
            
            HStack(spacing: 16) {
                // 1. Database
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
                
                // 2. Flashcard
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
