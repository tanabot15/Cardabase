//
//  SettingsView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var adManager = AdMobManager.shared
    @Query private var folders: [Folder]
    
    @State private var isShowingPaywall: Bool = false
    
    var body: some View {
        List {
            // acount
            Section(header: Text("Plan Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adManager.isProUser ? "Cardabase Pro" : "Free Plan")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(adManager.isProUser ? "Unlimited databases and ad-free experience." : "Limited to \(Limits.maxFoldersForFree) databases & \(Limits.maxKnowledgesPerFolderForFree) records per database.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if adManager.isProUser {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
                
                if !adManager.isProUser {
                    Button(action: { isShowingPaywall = true }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Upgrade to Pro")
                                .bold()
                        }
                    }
                }
            }
            
            // data statistics
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Databases")
                    Spacer()
                    Text("\(folders.count) / \(adManager.isProUser ? "∞" : "\(Limits.maxFoldersForFree)")")
                        .foregroundStyle(.secondary)
                }
            }
            
            // app info
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
                
                Button("Restore Purchases") {
                    Task {
                        try? await adManager.restorePurchases()
                    }
                }
            }
        }
        .navigationTitle("Setting")
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
    }
}
