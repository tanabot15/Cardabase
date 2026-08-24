//
//  DataTransferManager.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/08/24.
//

import Foundation
import SwiftData

struct ExportableKnowledge: Codable {
    let title: String
    let summary: String
    let customFields: [String: String]
}

struct ExportableFolder: Codable {
    let name: String
    let knowledges: [ExportableKnowledge]
}

@MainActor
final class DataTransferManager {
    
    // MARK: - Export (JSON)
    static func exportToJSON(folders: [Folder]) -> URL? {
        let exportData = folders.map { folder in
            ExportableFolder(
                name: folder.name,
                knowledges: folder.knowledges.map { k in
                    var fields: [String: String] = [:]
                    for field in k.customFields {
                        fields[field.key] = field.value
                    }
                    return ExportableKnowledge(title: k.title, summary: k.summary, customFields: fields)
                }
            )
        }
        
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(exportData) else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Cardabase_Backup_\(dateFormatter.string(from: Date())).json")
        try? data.write(to: tempURL)
        return tempURL
    }
    
    // MARK: - Export (CSV - 1 Folder)
    static func exportToCSV(folder: Folder) -> URL? {
        var csvText = "Title,Summary\n"
        for k in folder.knowledges {
            let escapedTitle = k.title.replacingOccurrences(of: "\"", with: "\"\"")
            let escapedSummary = k.summary.replacingOccurrences(of: "\"", with: "\"\"")
            csvText += "\"\(escapedTitle)\",\"\(escapedSummary)\"\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(folder.name)_Export.csv")
        try? csvText.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    // MARK: - Import (CSV into Folder)
    static func importCSV(url: URL, targetFolder: Folder, context: ModelContext) -> Int {
        guard url.startAccessingSecurityScopedResource() else { return 0 }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return 0 }
        let lines = content.components(separatedBy: .newlines)
        var count = 0
        
        for (index, line) in lines.enumerated() {
            if index == 0 || line.trimmingCharacters(in: .whitespaces).isEmpty { continue } // Header or empty
            
            let components = parseCSVLine(line)
            if !components.isEmpty {
                let title = components[0]
                let summary = components.count > 1 ? components[1] : ""
                
                let newKnowledge = Knowledge(title: title, summary: summary)
                newKnowledge.folder = targetFolder
                targetFolder.knowledges.append(newKnowledge)
                context.insert(newKnowledge)
                count += 1
            }
        }
        
        try? context.save()
        return count
    }
    
    // MARK: - Helper Utilities
    private static let encoder = JSONEncoder()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
}
