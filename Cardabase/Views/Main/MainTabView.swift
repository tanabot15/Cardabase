//
//  ContentView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData
import AppTrackingTransparency
import AdSupport

enum ViewMode {
    case database
    case flashcards
}

struct MainTabView: View {
    var body: some View {
        TabView {
            // 1. Databases Tab
            FolderListView(mode: .database)
                .tabItem {
                    Label("Databases", systemImage: "cylinder.split.1x2.fill")
                }
            
            // 2. Flashcards Tab
            FolderListView(mode: .flashcards)
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                }
            
            // 3. Analytics Tab (新規追加)
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
            
            // 4. Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            requestATTInView()
        }
    }
    
    /// Request App Tracking Transparency (ATT) authorization
    private func requestATTInView() {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    let context = container.mainContext
    
    let folder1 = Folder(name: "AI & Tech Concepts")
    folder1.knowledges.append(Knowledge(title: "Attention Mechanism", summary: "Calculates dynamic weights"))
    
    let folder2 = Folder(name: "Financial Indicators")
    let k1 = Knowledge(title: "ROIC", summary: "Return on Invested Capital")
    k1.masterStatus = .mastered
    folder2.knowledges.append(contentsOf: [
        k1,
        Knowledge(title: "PER", summary: "Price to Earnings Ratio"),
        Knowledge(title: "ROE", summary: "Return on Equity")
    ])
    
    let folder3 = Folder(name: "Intellectual Property")
    
    context.insert(folder1)
    context.insert(folder2)
    context.insert(folder3)
    
    return MainTabView()
        .modelContainer(container)
}
