//
//  ContentView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

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
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Setting", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
