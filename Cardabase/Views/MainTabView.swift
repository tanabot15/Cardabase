//
//  MainTabView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Folder.createdAt, order: .reverse) private var allFolders: [Folder]
    
    @State private var selectedTab: Int = 0
    @State private var isShowingQuickAddActionSheet: Bool = false
    
    // Quick Add モーダルの状態管理
    @State private var isShowingSingleAdd: Bool = false
    @State private var isShowingBulkAdd: Bool = false
    @State private var isShowingVoiceAdd: Bool = false
    @State private var isShowingCreateFolder: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Unified Databases & Flashcards Tab
            NavigationStack {
                FolderListView()
            }
            .tabItem {
                Label {
                    Text("Folder")
                } icon: {
                    Image(systemName: "folder")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                }
            }
            .tag(0)
            
            // 2. Global Search & Discovery Tab
            NavigationStack {
                GlobalSearchView()
            }
            .tabItem {
                Label {
                    Text("Search")
                } icon: {
                    Image(systemName: "magnifyingglass.circle")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                }
            }
            .tag(1)
            
            // 3. Quick Add Button (Dummy Tab)
            Color.clear
                .tabItem {
                    Label {
                        Text("Add")
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .tag(2)
            
            // 4. Analytics Tab
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label {
                    Text("Analytics")
                } icon: {
                    Image(systemName: "chart.pie")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                }
            }
            .tag(3)
            
            // 5. Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: "gearshape")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                }
            }
            .tag(4)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == 2 {
                selectedTab = oldTab
                handleGlobalAddTapped()
            }
        }
        .confirmationDialog("Quick Add", isPresented: $isShowingQuickAddActionSheet, titleVisibility: .visible) {
            Button("New Database / Folder") {
                handleCreateFolderTapped()
            }
            
            Button("Add Single Record") {
                isShowingSingleAdd = true
            }
            .disabled(allFolders.isEmpty)
            
            Button("Add Bulk Records") {
                isShowingBulkAdd = true
            }
            .disabled(allFolders.isEmpty)
            
            Button("Add by Voice") {
                isShowingVoiceAdd = true
            }
            .disabled(allFolders.isEmpty)
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingSingleAdd) {
            if let folder = targetFolder {
                KnowledgeFormView(folder: folder)
            }
        }
        .sheet(isPresented: $isShowingBulkAdd) {
            if let folder = targetFolder {
                QuickAddView(folder: folder)
            }
        }
        .sheet(isPresented: $isShowingVoiceAdd) {
            if let folder = targetFolder {
                VoiceCardInputSheet(folder: folder)
            }
        }
        .sheet(isPresented: $isShowingCreateFolder) {
            FolderFormView()
        }
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
    }
    
    /// 保存先フォルダーの決定（フォルダーが存在しない場合は最初のものを自動選択）
    private var targetFolder: Folder? {
        allFolders.first
    }
    
    private func handleGlobalAddTapped() {
        isShowingQuickAddActionSheet = true
    }
    
    private func handleCreateFolderTapped() {
        if Limits.isFolderLimitReached(currentCount: allFolders.count, isPro: appState.isProUser) {
            appState.isShowingPaywall = true
        } else {
            isShowingCreateFolder = true
        }
    }
}

// MARK: - Preview Helper

@MainActor
private func createPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA Exam")
    let folder2 = Folder(name: "Financial Indicators")
    context.insert(folder1)
    context.insert(folder2)
    
    let k1 = Knowledge(title: "Yamada Nishiki", summary: "King of Sake Rice produced mainly in Hyogo Pref.")
    k1.folder = folder1
    
    let k2 = Knowledge(title: "ROIC", summary: "Return on Invested Capital", masterStatus: .mastered)
    let k3 = Knowledge(title: "PER", summary: "Price to Earnings Ratio")
    let k4 = Knowledge(title: "ROE", summary: "Return on Equity")
    k2.folder = folder2
    k3.folder = folder2
    k4.folder = folder2
    
    context.insert(k1)
    context.insert(k2)
    context.insert(k3)
    context.insert(k4)
    
    return container
}

// MARK: - Previews

#Preview("Light") {
    MainTabView()
        .environmentObject(AppState())
        .modelContainer(createPreviewContainer())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MainTabView()
        .environmentObject(AppState())
        .modelContainer(createPreviewContainer())
        .preferredColorScheme(.dark)
}
