//
//  DataManagementView.swift
//  Cardabase
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View responsible for backup and restore of database content (JSON / CSV formats).
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
            // MARK: Backup Section
            Section(
                header: Text("Data Backup (Export)"),
                footer: Text("Export all data to JSON format or export a specific database to CSV.")
            ) {
                Button(action: exportAllJSON) {
                    Label("Backup All Data (JSON)", systemImage: "doc.badge.plus")
                }
                .disabled(folders.isEmpty)
                
                Picker("Target Database (CSV)", selection: $selectedFolderForCSV) {
                    Text("Select Database").tag(Folder?.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Folder?.some(folder))
                    }
                }
                
                if let target = selectedFolderForCSV {
                    Button(action: { exportCSV(folder: target) }) {
                        Label("Export '\(target.name)' to CSV", systemImage: "tablecells")
                    }
                }
            }
            
            // MARK: Restore / Import Section
            Section(header: Text("Data Restore (Import)")) {
                Button(action: { isShowingFileImporter = true }) {
                    Label("Restore / Import from CSV File", systemImage: "square.and.arrow.down")
                }
                .disabled(selectedFolderForCSV == nil)
            }
        }
        .navigationTitle("Data Backup & Restore")
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
        .alert("Status", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Methods
    private func handleImport(result: Result<[URL], Error>) {
        guard let targetFolder = selectedFolderForCSV else { return }
        
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                let count = DataTransferManager.importCSV(url: selectedURL, targetFolder: targetFolder, context: modelContext)
                alertMessage = "Successfully restored \(count) records into '\(targetFolder.name)'."
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
