//
//  DataManagementView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/08/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var folders: [Folder]
    
    @State private var selectedFolderForCSV: Folder?
    @State private var isShowingFileImporter = false
    @State private var isShowingShareSheet = false
    @State private var exportURL: URL?
    
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    
    var body: some View {
        Form {
            if !appState.isProUser {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)
                        
                        Text("Pro Feature Required")
                            .font(.headline)
                        
                        Text("CSV/JSON Import & Export is exclusive to Cardabase Pro users.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { appState.isShowingPaywall = true }) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // MARK: - Import CSV
            Section(header: Text("Import Data")) {
                Picker("Target Database", selection: $selectedFolderForCSV) {
                    Text("Select Database").tag(Folder?.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Folder?.some(folder))
                    }
                }
                
                Button(action: { isShowingFileImporter = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import CSV File")
                    }
                }
                .disabled(selectedFolderForCSV == nil || !appState.isProUser)
            }
            
            // MARK: - Export Data
            Section(header: Text("Export & Backup")) {
                Button(action: exportAllJSON) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Export All Data (JSON Backup)")
                    }
                }
                .disabled(folders.isEmpty || !appState.isProUser)
                
                if let target = selectedFolderForCSV {
                    Button(action: { exportCSV(folder: target) }) {
                        HStack {
                            Image(systemName: "tablecells")
                            Text("Export '\(target.name)' to CSV")
                        }
                    }
                    .disabled(!appState.isProUser)
                }
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
        .alert("Import Status", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Handlers
    private func handleImport(result: Result<[URL], Error>) {
        guard let targetFolder = selectedFolderForCSV else { return }
        
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                let count = DataTransferManager.importCSV(url: selectedURL, targetFolder: targetFolder, context: modelContext)
                alertMessage = "Successfully imported \(count) records into '\(targetFolder.name)'."
                isShowingAlert = true
            }
        case .failure(let error):
            alertMessage = "Failed to import file: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }
    
    private func exportAllJSON() {
        if let url = DataTransferManager.exportToJSON(folders: folders) {
            exportURL = url
            isShowingShareSheet = true
        }
    }
    
    private func exportCSV(folder: Folder) {
        if let url = DataTransferManager.exportToCSV(folder: folder) {
            exportURL = url
            isShowingShareSheet = true
        }
    }
}

// UIActivityViewController wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataManagementView()
}
