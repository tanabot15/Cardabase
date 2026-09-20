//
//  MainTabView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData
import AppTrackingTransparency

enum ViewMode {
    case database
    case flashcards
}

struct MainTabView: View {
    var body: some View {
        TabView {
            // 1. Databases Tab
            NavigationStack {
                FolderListView(mode: .database)
            }
            .tabItem {
                Label("Databases", systemImage: "cylinder.split.1x2.fill")
            }
            
            // 2. Flashcards Tab
            NavigationStack {
                FolderListView(mode: .flashcards)
            }
            .tabItem {
                Label("Flashcards", systemImage: "rectangle.on.rectangle.angled.fill")
            }
            
            // 3. Analytics Tab
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.pie.fill")
            }
            
            // 4. Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .onAppear {
            requestATTAuthorization()
        }
    }
    
    // MARK: - Private Methods
    
    /// Request App Tracking Transparency authorization for ad personalized tracking
    private func requestATTAuthorization() {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
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
