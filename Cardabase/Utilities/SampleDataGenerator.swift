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
        
        // 3-1. ROIC
        let roic = Knowledge(
            title: "ROIC",
            summary: "Return on Invested Capital. Measures how efficiently a company allocates capital to generate profits.",
            customFields: [
                FieldValue(key: "Formula", value: "NOPAT / Invested Capital", type: .text),
                FieldValue(key: "Benchmark", value: "> 8%", type: .text),
                FieldValue(key: "Tag", value: "Profitability", type: .tag)
            ]
        )
        
        // 3-2. PER
        let per = Knowledge(
            title: "PER",
            summary: "Price to Earnings Ratio. Indicates how much investors are paying per dollar of net income.",
            customFields: [
                FieldValue(key: "Formula", value: "Share Price / EPS", type: .text),
                FieldValue(key: "Benchmark", value: "15x - 20x", type: .text),
                FieldValue(key: "Tag", value: "Valuation", type: .tag)
            ]
        )
        
        // 3-3. PBR
        let pbr = Knowledge(
            title: "PBR",
            summary: "Price to Book Ratio. Compares a market capitalization to its book value.",
            customFields: [
                FieldValue(key: "Formula", value: "Share Price / BPS", type: .text),
                FieldValue(key: "Benchmark", value: "> 1.0x", type: .text),
                FieldValue(key: "Tag", value: "Valuation", type: .tag)
            ]
        )
        
        // 3-4. ROE
        let roe = Knowledge(
            title: "ROE",
            summary: "Return on Equity. Measures profitability by revealing how much profit a company generates with shareholders' equity.",
            customFields: [
                FieldValue(key: "Formula", value: "Net Income / Shareholders' Equity", type: .text),
                FieldValue(key: "Benchmark", value: "> 8%", type: .text),
                FieldValue(key: "Tag", value: "Profitability", type: .tag)
            ]
        )
        
        // 3-5. ROA
        let roa = Knowledge(
            title: "ROA",
            summary: "Return on Assets. Indicates how profitable a company is relative to its total assets.",
            customFields: [
                FieldValue(key: "Formula", value: "Net Income / Total Assets", type: .text),
                FieldValue(key: "Benchmark", value: "> 5%", type: .text),
                FieldValue(key: "Tag", value: "Profitability", type: .tag)
            ]
        )
        
        // 3-6. EV/EBITDA
        let evEbitda = Knowledge(
            title: "EV / EBITDA",
            summary: "Enterprise Multiple. Compares the value of a company, inclusive of debt, to the cash earnings minus non-cash expenses.",
            customFields: [
                FieldValue(key: "Formula", value: "Enterprise Value / EBITDA", type: .text),
                FieldValue(key: "Benchmark", value: "< 10x", type: .text),
                FieldValue(key: "Tag", value: "Valuation", type: .tag)
            ]
        )
        
        // 3-7. Free Cash Flow
        let fcf = Knowledge(
            title: "Free Cash Flow",
            summary: "Represents the cash a company generates after accounting for cash outflows to support operations and capital expenditures.",
            customFields: [
                FieldValue(key: "Formula", value: "Operating Cash Flow - Capital Expenditures", type: .text),
                FieldValue(key: "Benchmark", value: "Positive & Growing", type: .text),
                FieldValue(key: "Tag", value: "Cash Flow", type: .tag)
            ]
        )
        
        // 3-8. Equity Ratio
        let equityRatio = Knowledge(
            title: "Equity Ratio",
            summary: "Measures the proportion of total assets that are financed by stockholders' equity, reflecting financial stability.",
            customFields: [
                FieldValue(key: "Formula", value: "Total Equity / Total Assets", type: .text),
                FieldValue(key: "Benchmark", value: "> 40%", type: .text),
                FieldValue(key: "Tag", value: "Health", type: .tag)
            ]
        )
        
        // 3-9. Dividend Yield
        let dividendYield = Knowledge(
            title: "Dividend Yield",
            summary: "Shows how much a company pays out in dividends each year relative to its stock price.",
            customFields: [
                FieldValue(key: "Formula", value: "Annual Dividend Per Share / Share Price", type: .text),
                FieldValue(key: "Benchmark", value: "3.0% - 4.0%", type: .text),
                FieldValue(key: "Tag", value: "Shareholder Return", type: .tag)
            ]
        )
        
        // 3-10. Payout Ratio
        let payoutRatio = Knowledge(
            title: "Payout Ratio",
            summary: "The proportion of earnings paid out as dividends to shareholders.",
            customFields: [
                FieldValue(key: "Formula", value: "Total Dividends / Net Income", type: .text),
                FieldValue(key: "Benchmark", value: "30% - 50%", type: .text),
                FieldValue(key: "Tag", value: "Shareholder Return", type: .tag)
            ]
        )
        
        financeFolder.knowledges.append(contentsOf: [
            roic, per, pbr, roe, roa, evEbitda, fcf, equityRatio, dividendYield, payoutRatio
        ])
                
        // save to database
        modelContext.insert(techFolder)
        modelContext.insert(ipFolder)
        modelContext.insert(financeFolder)
                
        // update flag
        UserDefaults.standard.set(true, forKey: hasInsertedSampleKey)
    }
}
