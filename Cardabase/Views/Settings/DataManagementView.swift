//
//  DataManagementView.swift
//  Cardabase
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Cleaned & simplified view for data backup, restore, and CSV transfer.
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var folders: [Folder]
    
    // MARK: - State
    @State private var selectedFolderForCSV: Folder?
    
    // File Importers & Exporters
    @State private var isShowingJSONImporter = false
    @State private var isShowingCSVImporter = false
    @State private var isShowingShareSheet = false
    @State private var exportURL: URL?
    
    // Alert State
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    
    var body: some View {
        Form {
            // MARK: 1. Full Backup & Restore (JSON)
            Section {
                Button(action: exportAllJSON) {
                    Label("Backup All Data (JSON)", systemImage: "arrow.up.doc.fill")
                }
                .disabled(folders.isEmpty)
                
                Button(action: { isShowingJSONImporter = true }) {
                    Label("Restore All Data from Backup", systemImage: "arrow.clockwise.icloud.fill")
                }
            } header: {
                Text("Full App Backup & Restore")
            } footer: {
                Text("Use JSON backups to safely save or restore your entire database, including custom attributes.")
            }
            
            // MARK: 2. Single Database Transfer (CSV)
            Section {
                Picker("Select Target Database", selection: $selectedFolderForCSV) {
                    Text("Select Database").tag(Folder?.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Folder?.some(folder))
                    }
                }
                
                if let target = selectedFolderForCSV {
                    Button(action: { exportCSV(folder: target) }) {
                        Label("Export '\(target.name)' to CSV", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { isShowingCSVImporter = true }) {
                        Label("Import Cards into '\(target.name)'", systemImage: "square.and.arrow.down")
                    }
                }
            } header: {
                Text("Single Database CSV Transfer")
            } footer: {
                Text("Export or import individual cards in CSV format for spreadsheet editing.")
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - File Importers
        .fileImporter(
            isPresented: $isShowingJSONImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleJSONImport(result: result)
        }
        .fileImporter(
            isPresented: $isShowingCSVImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result: result)
        }
        // MARK: - Share Sheet
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        // MARK: - Status Alert
        .alert("Data Management", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Handlers & Actions
    
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
    
    private func handleJSONImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                let count = DataTransferManager.importJSON(url: selectedURL, context: modelContext)
                alertMessage = "Successfully restored \(count) cards from backup."
                isShowingAlert = true
            }
        case .failure(let error):
            alertMessage = "Failed to import JSON file: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }
    
    private func handleCSVImport(result: Result<[URL], Error>) {
        guard let targetFolder = selectedFolderForCSV else { return }
        
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                let count = DataTransferManager.importCSV(url: selectedURL, targetFolder: targetFolder, context: modelContext)
                alertMessage = "Successfully imported \(count) records into '\(targetFolder.name)'."
                isShowingAlert = true
            }
        case .failure(let error):
            alertMessage = "Failed to import CSV file: \(error.localizedDescription)"
            isShowingAlert = true
        }
    }
}

// MARK: - ShareSheet UIKit Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    
    let sampleFolder = Folder(name: "Sample Portfolio")
    container.mainContext.insert(sampleFolder)
    
    let appState = AppState()
    
    return NavigationStack {
        DataManagementView()
            .modelContainer(container)
            .environmentObject(appState)
    }
}
