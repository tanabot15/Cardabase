//
//  VoiceParser.swift
//  Cardabase
//

import Foundation

struct ParsedVoiceResult {
    var title: String = ""
    var summary: String = ""
    var customFields: [FieldValue] = []
}

struct VoiceParser {
    /// 認識されたテキストと Folder のスキーマからフィールドを分割
    static func parse(text: String, folder: Folder) -> ParsedVoiceResult {
        var result = ParsedVoiceResult()
        
        // 判定キーワードの定義 (揺らぎ吸収)
        let titleKeywords = ["タイトル", "たいとる", "表", "おもて", "問題"]
        let summaryKeywords = ["概要", "がいよう", "裏", "うら", "答え", "こたえ", "サマリー"]
        
        // スキーマに含まれるカスタムフィールドキーとその揺らぎマップ
        let customSchemas = folder.customFieldSchemas
        
        // 分割用のトークンプレフィックスを生成
        var segments: [(key: String, text: String)] = []
        
        // キーワードの位置で分割するための正規表現パターン作成
        var allKeywords: [String] = []
        allKeywords.append(contentsOf: titleKeywords)
        allKeywords.append(contentsOf: summaryKeywords)
        for schema in customSchemas {
            allKeywords.append(schema.key)
        }
        
        // 文字列長が長い順に並び替え (誤マッチ防止)
        allKeywords.sort { $0.count > $1.count }
        
        let pattern = "(?i)(" + allKeywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            result.title = text
            return result
        }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        if matches.isEmpty {
            // キーワードがない場合は全文をタイトルに割り当てる
            result.title = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return result
        }
        
        // キーワードで区切られた区間をパース
        for i in 0..<matches.count {
            let match = matches[i]
            let keyword = nsText.substring(with: match.range)
            
            let startIndex = match.range.location + match.range.length
            let endIndex = (i + 1 < matches.count) ? matches[i + 1].range.location : nsText.length
            let valueLength = endIndex - startIndex
            
            let value = nsText.substring(with: NSRange(location: startIndex, length: valueLength))
                .trimmingCharacters(in: .init(charactersIn: " ：:、,。"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            segments.append((key: keyword, text: value))
        }
        
        // 収集したセグメントを該当項目へマッピング
        var customFieldValues: [String: String] = [:]
        
        for segment in segments {
            let key = segment.key
            let value = segment.text
            
            if titleKeywords.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                result.title = value
            } else if summaryKeywords.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                result.summary = value
            } else if let matchedSchema = customSchemas.first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
                customFieldValues[matchedSchema.key] = value
            }
        }
        
        // カスタムフィールド配列を組み上げる
        result.customFields = customSchemas.map { schema in
            FieldValue(key: schema.key, value: customFieldValues[schema.key] ?? "", type: schema.type)
        }
        
        return result
    }
}
