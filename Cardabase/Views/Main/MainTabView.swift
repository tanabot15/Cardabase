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

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FolderListView()
            }
            .tabItem {
                Label("Folder", systemImage: "folder.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Setting", systemImage: "gearshape.fill")
            }
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
