//
//  SampleDataGenerator.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import Foundation
import SwiftData

@MainActor
struct SampleDataGenerator {
    private static let hasInsertedSampleKey = "HasInsertedSampleData_v1"
    
    static func insertSampleDataIfNeeded(modelContext: ModelContext) {
        // skip if there is enough data
        guard !UserDefaults.standard.bool(forKey: hasInsertedSampleKey) else { return }
        
        // 1. AI & Tech Concepts
        let techFolder = Folder(
            name: "AI & Tech Concepts",
            defaultFrontKey: "Title",
            defaultBackKey: "Summary"
        )
        let techKnowledge = Knowledge(
            title: "Attention Mechanism",
            summary: "Calculates dynamic weights for elements in a sequence to capture long-range dependencies.",
            customFields: [
                FieldValue(key: "Year", value: "2017", type: .number),
                FieldValue(key: "Source", value: "https://arxiv.org/abs/1706.03762", type: .url),
                FieldValue(key: "Tag", value: "Deep Learning", type: .tag)
            ]
        )
        techFolder.knowledges.append(techKnowledge)
        
        // 2. Intellectual Property
        let ipFolder = Folder(
            name: "Intellectual Property",
            defaultFrontKey: "Title",
            defaultBackKey: "Requirement"
        )
        let ipKnowledge = Knowledge(
            title: "Trade Secret",
            summary: "Confidential business information which provides a competitive edge.",
            customFields: [
                FieldValue(key: "Requirement", value: "Secrecy, Commercial Value, Non-public", type: .text),
                FieldValue(key: "Protection Period", value: "Indefinite", type: .text),
                FieldValue(key: "Source", value: "Unfair Competition Prevention Act", type: .text)
            ]
        )
        ipFolder.knowledges.append(ipKnowledge)
                
        // 3. Financial Indicators
        let financeFolder = Folder(
            name: "Financial Indicators",
            defaultFrontKey: "Title",
            defaultBackKey: "Formula"
        )
        let financeKnowledge = Knowledge(
            title: "ROIC",
            summary: "Return on Invested Capital. Measures how efficiently a company allocates capital to generate profits.",
            customFields: [
                FieldValue(key: "Formula", value: "NOPAT / Invested Capital", type: .text),
                FieldValue(key: "Benchmark", value: "> 8%", type: .text),
                FieldValue(key: "Tag", value: "Valuation", type: .tag)
            ]
        )
        financeFolder.knowledges.append(financeKnowledge)
                
        // save to database
        modelContext.insert(techFolder)
        modelContext.insert(ipFolder)
        modelContext.insert(financeFolder)
                
        // update flag
        UserDefaults.standard.set(true, forKey: hasInsertedSampleKey)
    }
}
