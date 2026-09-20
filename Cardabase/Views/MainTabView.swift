//
//  MainTabView.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            // 1. Unified Databases & Flashcards Tab
            NavigationStack {
                FolderListView()
            }
            .tabItem {
                Label("Folder", systemImage: "folder.fill")
            }
            
            // 2. Analytics Tab
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.pie.fill")
            }
            
            // 3. Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "SAKE DIPLOMA Exam")
    folder1.knowledges.append(Knowledge(title: "Yamada Nishiki", summary: "King of Sake Rice produced mainly in Hyogo Pref."))
    
    let folder2 = Folder(name: "Financial Indicators")
    let k1 = Knowledge(title: "ROIC", summary: "Return on Invested Capital")
    k1.masterStatus = .mastered
    folder2.knowledges.append(contentsOf: [
        k1,
        Knowledge(title: "PER", summary: "Price to Earnings Ratio"),
        Knowledge(title: "ROE", summary: "Return on Equity")
    ])
    
    context.insert(folder1)
    context.insert(folder2)
    
    return MainTabView()
        .environmentObject(AppState())
        .modelContainer(container)
}
