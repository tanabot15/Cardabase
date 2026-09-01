//
//  SettingsView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var adManager = AdMobManager.shared
    @Query private var folders: [Folder]
    
    @AppStorage("userColorScheme") private var userColorScheme: Int = 0
    @AppStorage(SampleDataGenerator.hasInsertedSampleKey) private var hasInsertedSampleData: Bool = false
    
    // for Pro
//    @State private var isShowingPaywall: Bool = false
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $userColorScheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.menu)
            }
            
            // MARK: - Plan Status
            // acount
//            Section(header: Text("Plan Status")) {
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        // delete for Pro
//                        Text("Free Plan")
//                            .font(.headline)
//                            .foregroundStyle(.primary)
//                                                
//                        Text("All features are available with supported ads.")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                        
//                         for Pro
//                        Text(adManager.isProUser ? "Cardabase Pro" : "Free Plan")
//                            .font(.headline)
//                            .foregroundStyle(.primary)
//                        
//                        Text(adManager.isProUser ? "Unlimited databases and ad-free experience." : "Limited to \(Limits.maxFoldersForFree) databases & \(Limits.maxKnowledgesPerFolderForFree) records per database.")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                    Spacer()
//                     for Pro
//                    if adManager.isProUser {
//                        Image(systemName: "checkmark.seal.fill")
//                            .font(.title2)
//                            .foregroundStyle(.green)
//                    }
//                }
//                .padding(.vertical, 4)
//                
//                 for Pro
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
//            }
            
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
            
            // Data Management Section
            Section(header: Text("Data Management")) {
                Button(action: {
                    SampleDataGenerator.insertSampleDataIfNeeded(modelContext: modelContext)
                }) {
                    HStack {
                        Text(hasInsertedSampleData ? "Sample Data Loaded" : "Load Sample Data")
                    }
                }
                .disabled(hasInsertedSampleData)
                
                NavigationLink(destination: DataManagementView()) {
                    Text("Data Import / Export")
                }
            }
            
            // app info
            Section(header: Text("About App")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.5")
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
        .navigationBarTitleDisplayMode(.inline)
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
