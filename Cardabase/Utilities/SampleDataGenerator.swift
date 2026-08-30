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
    static let hasInsertedSampleKey = "HasInsertedSampleData_v2"
    
    static func insertSampleDataIfNeeded(modelContext: ModelContext) {
        // Skip if sample data has already been generated
        guard !UserDefaults.standard.bool(forKey: hasInsertedSampleKey) else { return }
        
        // ==========================================
        // 1. Financial Indicators (10 items)
        // ==========================================
        let financeSchemas = [
            FieldSchema(key: "Formula", type: .text),
            FieldSchema(key: "Benchmark", type: .text),
            FieldSchema(key: "Tag", type: .tag)
        ]
        
        let financeFolder = Folder(
            name: "Financial Indicators",
            defaultFrontKey: "Title",
            defaultBackKey: "Summary",
            customFieldSchemas: financeSchemas
        )
        
        financeFolder.knowledges = [
            Knowledge(
                title: "PER",
                summary: "Price to Earnings Ratio. Indicates how much investors pay per dollar of net income.",
                customFields: [
                    FieldValue(key: "Formula", value: "Share Price / EPS", type: .text),
                    FieldValue(key: "Benchmark", value: "15x - 20x", type: .text),
                    FieldValue(key: "Tag", value: "Valuation", type: .tag)
                ]
            ),
            Knowledge(
                title: "PBR",
                summary: "Price to Book Ratio. Compares market capitalization to book value.",
                customFields: [
                    FieldValue(key: "Formula", value: "Share Price / BPS", type: .text),
                    FieldValue(key: "Benchmark", value: "> 1.0x", type: .text),
                    FieldValue(key: "Tag", value: "Valuation", type: .tag)
                ]
            ),
            Knowledge(
                title: "ROIC",
                summary: "Return on Invested Capital. Measures how efficiently capital is allocated to generate profits.",
                customFields: [
                    FieldValue(key: "Formula", value: "NOPAT / Invested Capital", type: .text),
                    FieldValue(key: "Benchmark", value: "> 8%", type: .text),
                    FieldValue(key: "Tag", value: "Profitability", type: .tag)
                ]
            ),
            Knowledge(
                title: "ROE",
                summary: "Return on Equity. Measures profitability generated with shareholders' equity.",
                customFields: [
                    FieldValue(key: "Formula", value: "Net Income / Shareholders' Equity", type: .text),
                    FieldValue(key: "Benchmark", value: "> 8%", type: .text),
                    FieldValue(key: "Tag", value: "Profitability", type: .tag)
                ]
            ),
            Knowledge(
                title: "ROA",
                summary: "Return on Assets. Indicates profitability relative to total assets.",
                customFields: [
                    FieldValue(key: "Formula", value: "Net Income / Total Assets", type: .text),
                    FieldValue(key: "Benchmark", value: "> 5%", type: .text),
                    FieldValue(key: "Tag", value: "Profitability", type: .tag)
                ]
            ),
            Knowledge(
                title: "EV / EBITDA",
                summary: "Enterprise Multiple. Compares company value inclusive of debt to EBITDA.",
                customFields: [
                    FieldValue(key: "Formula", value: "Enterprise Value / EBITDA", type: .text),
                    FieldValue(key: "Benchmark", value: "< 10x", type: .text),
                    FieldValue(key: "Tag", value: "Valuation", type: .tag)
                ]
            ),
            Knowledge(
                title: "Free Cash Flow",
                summary: "Cash generated after operating expenses and capital expenditures.",
                customFields: [
                    FieldValue(key: "Formula", value: "Operating Cash Flow - CapEx", type: .text),
                    FieldValue(key: "Benchmark", value: "Positive & Growing", type: .text),
                    FieldValue(key: "Tag", value: "Cash Flow", type: .tag)
                ]
            ),
            Knowledge(
                title: "Equity Ratio",
                summary: "Proportion of total assets financed by stockholders' equity.",
                customFields: [
                    FieldValue(key: "Formula", value: "Total Equity / Total Assets", type: .text),
                    FieldValue(key: "Benchmark", value: "> 40%", type: .text),
                    FieldValue(key: "Tag", value: "Health", type: .tag)
                ]
            ),
            Knowledge(
                title: "Dividend Yield",
                summary: "Annual dividend payout relative to share price.",
                customFields: [
                    FieldValue(key: "Formula", value: "Dividend Per Share / Share Price", type: .text),
                    FieldValue(key: "Benchmark", value: "3.0% - 4.0%", type: .text),
                    FieldValue(key: "Tag", value: "Shareholder Return", type: .tag)
                ]
            ),
            Knowledge(
                title: "Payout Ratio",
                summary: "Proportion of net earnings paid out as dividends.",
                customFields: [
                    FieldValue(key: "Formula", value: "Total Dividends / Net Income", type: .text),
                    FieldValue(key: "Benchmark", value: "30% - 50%", type: .text),
                    FieldValue(key: "Tag", value: "Shareholder Return", type: .tag)
                ]
            )
        ]
        
        // ==========================================
        // 2. Wine Grape Varieties (10 items)
        // ==========================================
        let wineSchemas = [
            FieldSchema(key: "Color", type: .text),
            FieldSchema(key: "Taste", type: .text),
            FieldSchema(key: "Main Country", type: .text)
        ]
        
        let wineFolder = Folder(
            name: "Wine Grape Varieties",
            defaultFrontKey: "Title",
            defaultBackKey: "Summary",
            customFieldSchemas: wineSchemas
        )
        
        wineFolder.knowledges = [
            Knowledge(
                title: "Cabernet Sauvignon",
                summary: "Full-bodied red variety known for high tannins, acidity, and black currant notes.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Full-bodied, Bold, Tannic", type: .text),
                    FieldValue(key: "Main Country", value: "France (Bordeaux), USA", type: .text)
                ]
            ),
            Knowledge(
                title: "Pinot Noir",
                summary: "Light to medium-bodied red variety with cherry, red fruit, and earthy undertones.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Light-bodied, Elegant, Fruity", type: .text),
                    FieldValue(key: "Main Country", value: "France (Burgundy), USA, NZ", type: .text)
                ]
            ),
            Knowledge(
                title: "Merlot",
                summary: "Medium to full-bodied red variety with plum, black cherry, and soft tannin profile.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Medium-bodied, Soft, Smooth", type: .text),
                    FieldValue(key: "Main Country", value: "France (Bordeaux), USA", type: .text)
                ]
            ),
            Knowledge(
                title: "Syrah / Shiraz",
                summary: "Bold red grape producing wines with blackberry, black pepper, and smoky character.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Full-bodied, Spicy, Rich", type: .text),
                    FieldValue(key: "Main Country", value: "France (Rhône), Australia", type: .text)
                ]
            ),
            Knowledge(
                title: "Chardonnay",
                summary: "Versatile white grape ranging from crisp citrus to buttery, oak-aged flavors.",
                customFields: [
                    FieldValue(key: "Color", value: "White", type: .text),
                    FieldValue(key: "Taste", value: "Medium to Full, Rich, Creamy", type: .text),
                    FieldValue(key: "Main Country", value: "France (Burgundy), USA", type: .text)
                ]
            ),
            Knowledge(
                title: "Sauvignon Blanc",
                summary: "Aromatic white grape with crisp acidity, grass, green apple, and tropical nuances.",
                customFields: [
                    FieldValue(key: "Color", value: "White", type: .text),
                    FieldValue(key: "Taste", value: "Light, Zesty, Crisp", type: .text),
                    FieldValue(key: "Main Country", value: "New Zealand, France (Loire)", type: .text)
                ]
            ),
            Knowledge(
                title: "Riesling",
                summary: "High-acid white grape ranging from bone-dry to sweet, featuring floral and petroleum scents.",
                customFields: [
                    FieldValue(key: "Color", value: "White", type: .text),
                    FieldValue(key: "Taste", value: "High Acid, Aromatic, Off-dry/Dry", type: .text),
                    FieldValue(key: "Main Country", value: "Germany, France (Alsace)", type: .text)
                ]
            ),
            Knowledge(
                title: "Nebbiolo",
                summary: "Famous Italian red grape producing pale, highly tannic wines with rose and tar aromas.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Full-bodied, High Tannin, Earthy", type: .text),
                    FieldValue(key: "Main Country", value: "Italy (Piedmont)", type: .text)
                ]
            ),
            Knowledge(
                title: "Sangiovese",
                summary: "Core grape of Chianti, offering sour cherry, dried herb, and savory earthy notes.",
                customFields: [
                    FieldValue(key: "Color", value: "Red", type: .text),
                    FieldValue(key: "Taste", value: "Medium-bodied, High Acid, Savory", type: .text),
                    FieldValue(key: "Main Country", value: "Italy (Tuscany)", type: .text)
                ]
            ),
            Knowledge(
                title: "Koshu",
                summary: "Indigenous Japanese white grape variety producing crisp, delicate wines with citrus notes.",
                customFields: [
                    FieldValue(key: "Color", value: "White", type: .text),
                    FieldValue(key: "Taste", value: "Light, Fresh, Delicate", type: .text),
                    FieldValue(key: "Main Country", value: "Japan (Yamanashi)", type: .text)
                ]
            )
        ]
        
        // ==========================================
        // 3. Scientific Milestones (10 items)
        // ==========================================
        let scienceSchemas = [
            FieldSchema(key: "Year", type: .number),
            FieldSchema(key: "Source", type: .text)
        ]
        
        let scienceFolder = Folder(
            name: "Scientific Milestones",
            defaultFrontKey: "Title",
            defaultBackKey: "Summary",
            customFieldSchemas: scienceSchemas
        )
        
        scienceFolder.knowledges = [
            Knowledge(
                title: "Theory of General Relativity",
                summary: "Albert Einstein proposed that gravity is the curvature of spacetime caused by mass.",
                customFields: [
                    FieldValue(key: "Year", value: "1915", type: .number),
                    FieldValue(key: "Source", value: "Albert Einstein", type: .text)
                ]
            ),
            Knowledge(
                title: "Discovery of Penicillin",
                summary: "Alexander Fleming discovered the first effective antibiotic, revolutionizing modern medicine.",
                customFields: [
                    FieldValue(key: "Year", value: "1928", type: .number),
                    FieldValue(key: "Source", value: "Alexander Fleming", type: .text)
                ]
            ),
            Knowledge(
                title: "DNA Double Helix Structure",
                summary: "Watson, Crick, and Franklin identified the molecular structure of genetic material.",
                customFields: [
                    FieldValue(key: "Year", value: "1953", type: .number),
                    FieldValue(key: "Source", value: "Nature Journal", type: .text)
                ]
            ),
            Knowledge(
                title: "Periodic Law of Elements",
                summary: "Dmitri Mendeleev organized chemical elements by atomic mass and recurring properties.",
                customFields: [
                    FieldValue(key: "Year", value: "1869", type: .number),
                    FieldValue(key: "Source", value: "Dmitri Mendeleev", type: .text)
                ]
            ),
            Knowledge(
                title: "Law of Universal Gravitation",
                summary: "Isaac Newton formulated the force pulling masses together across the universe.",
                customFields: [
                    FieldValue(key: "Year", value: "1687", type: .number),
                    FieldValue(key: "Source", value: "Philosophiae Naturalis Principia Mathematica", type: .text)
                ]
            ),
            Knowledge(
                title: "Quantum Theory (Planck's Quantum)",
                summary: "Max Planck introduced quanta, laying the foundation for modern physics.",
                customFields: [
                    FieldValue(key: "Year", value: "1900", type: .number),
                    FieldValue(key: "Source", value: "Max Planck", type: .text)
                ]
            ),
            Knowledge(
                title: "CRISPR-Cas9 Gene Editing",
                summary: "Doudna and Charpentier developed a precise genome editing technology.",
                customFields: [
                    FieldValue(key: "Year", value: "2012", type: .number),
                    FieldValue(key: "Source", value: "Science Journal", type: .text)
                ]
            ),
            Knowledge(
                title: "Heliocentric Model",
                summary: "Nicolaus Copernicus proposed that Earth and planets revolve around the Sun.",
                customFields: [
                    FieldValue(key: "Year", value: "1543", type: .number),
                    FieldValue(key: "Source", value: "De revolutionibus orbium coelestium", type: .text)
                ]
            ),
            Knowledge(
                title: "Higgs Boson Discovery",
                summary: "CERN's Large Hadron Collider confirmed the existence of the particle giving mass to matter.",
                customFields: [
                    FieldValue(key: "Year", value: "2012", type: .number),
                    FieldValue(key: "Source", value: "CERN", type: .text)
                ]
            ),
            Knowledge(
                title: "Attention Is All You Need (Transformer)",
                summary: "Introduced the Transformer architecture, founding modern AI and LLMs.",
                customFields: [
                    FieldValue(key: "Year", value: "2017", type: .number),
                    FieldValue(key: "Source", value: "NeurIPS Paper", type: .text)
                ]
            )
        ]
        
        // Save folders to SwiftData Context
        modelContext.insert(financeFolder)
        modelContext.insert(wineFolder)
        modelContext.insert(scienceFolder)
        
        // Set flag to prevent duplicated generation
        UserDefaults.standard.set(true, forKey: hasInsertedSampleKey)
    }
}
