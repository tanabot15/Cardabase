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
            // 1. Database Tab
            NavigationStack {
                FolderListView(mode: .database)
            }
            .tabItem {
                Label("Folder", systemImage: "folder.fill")
            }
            
            // 2. Flashcards Tab
            NavigationStack {
                FolderListView(mode: .flashcards)
            }
            .tabItem {
                Label("Flashcards", systemImage: "rectangle.stack.fill")
            }
            
            // 3. Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Setting", systemImage: "gearshape.fill")
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
    MainTabView()
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
