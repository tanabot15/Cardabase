//
//  StudyResultView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct StudyResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    let folder: Folder
    let totalStudied: Int
    let correctCount: Int
    let incorrectCount: Int
    
    private var accuracyRate: Int {
        guard totalStudied > 0 else { return 0 }
        return Int(round(Double(correctCount) / Double(totalStudied) * 100))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                AdBannerView()
                
                Spacer()
                
                // icon
                Image(systemName: accuracyRate >= 80 ? "trophy.fill" : "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(accuracyRate >= 80 ? .yellow : Color.accentColor)
                
                VStack(spacing: 8) {
                    Text("Session Completed!")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("Great job studying '\(folder.name)'")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // score card
                HStack(spacing: 20) {
                    ResultStatBox(title: "Accuracy", value: "\(accuracyRate)%", color: .blue)
                    ResultStatBox(title: "Correct", value: "\(correctCount)%", color: .green)
                    ResultStatBox(title: "Incorrect", value: "\(incorrectCount)", color: .red)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // done
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

private struct ResultStatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let folder = Folder(name: "Sample Folder")
    return StudyResultView(folder: folder, totalStudied: 10, correctCount: 8, incorrectCount: 2)
}
