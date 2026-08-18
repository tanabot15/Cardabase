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
    
    // for Pro
//    @State private var isShowingPaywall: Bool = false
    
    var body: some View {
        List {
            // MARK: - Plan Status
            // acount
            Section(header: Text("Plan Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // delete for Pro
                        Text("Free Plan")
                            .font(.headline)
                            .foregroundStyle(.primary)
                                                
                        Text("All features are available with supported ads.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // for Pro
//                        Text(adManager.isProUser ? "Cardabase Pro" : "Free Plan")
//                            .font(.headline)
//                            .foregroundStyle(.primary)
//                        
//                        Text(adManager.isProUser ? "Unlimited databases and ad-free experience." : "Limited to \(Limits.maxFoldersForFree) databases & \(Limits.maxKnowledgesPerFolderForFree) records per database.")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    // for Pro
//                    if adManager.isProUser {
//                        Image(systemName: "checkmark.seal.fill")
//                            .font(.title2)
//                            .foregroundStyle(.green)
//                    }
                }
                .padding(.vertical, 4)
                
                // for Pro
//                if !adManager.isProUser {
//                    Button(action: { isShowingPaywall = true }) {
//                        HStack {
//                            Image(systemName: "star.fill")
//                                .foregroundStyle(.yellow)
//                            Text("Upgrade to Pro")
//                                .bold()
//                        }
//                    }
//                }
            }
            
            // data statistics
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Databases")
                    Spacer()
                    
                    // delete for Pro
                    Text("\(folders.count)")
                        .foregroundStyle(.secondary)
                    
                    // for Pro
//                    Text("\(folders.count) / \(adManager.isProUser ? "∞" : "\(Limits.maxFoldersForFree)")")
//                        .foregroundStyle(.secondary)
                }
            }
            
            // app info
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.1")
                        .foregroundStyle(.secondary)
                }
                
                // for Pro
//                Button("Restore Purchases") {
//                    Task {
//                        try? await adManager.restorePurchases()
//                    }
//                }
            }
        }
        .navigationTitle("Setting")
        // for Pro
//        .sheet(isPresented: $isShowingPaywall) {
//            PaywallView()
//        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
    }
}
