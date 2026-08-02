//
//  FlashcardView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct FlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    
    let folder: Folder
    let knowledges: [Knowledge]
    let frontKey: String
    let backKey: String
    
    // index management
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    
    // result tracking
    @State private var correctCount: Int = 0
    @State private var incorrectCount: Int = 0
    @State private var isCompleted: Bool = false
    
    private var currentKnowledge: Knowledge? {
        guard currentIndex < knowledges.count else { return nil }
        return knowledges[currentIndex]
    }
    
    // MARK: - Main view
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // progress bar
                ProgressView(value: Double(currentIndex), total: Double(knowledges.count))
                    .padding(.horizontal)
                
                HStack {
                    Text("Card \(currentIndex + 1) of \(knowledges.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // flip card
                if let knowledge = currentKnowledge {
                    ZStack {
                        // frond
                        CardFaceView(
                            title: frontKey,
                            content: knowledge.value(forKey: frontKey) ?? "(Empty)",
                            subHint: "Tap to flip"
                        )
                        .opacity(isFlipped ? 0.0 : 1.0)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        
                        // back
                        CardFaceView(
                            title: backKey,
                            content: knowledge.value(forKey: backKey) ?? "(Empty)",
                            subHint: "How was your recall?"
                        )
                        .opacity(isFlipped ? 1.0 : 0.0)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 0 : -180),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: 380)
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isFlipped.toggle()
                        }
                    }
                }
                
                Spacer()
                
                // action button (only back card)
                if isFlipped {
                    HStack(spacing: 20) {
                        Button(action: { recordAnswer(isCorrect: false) }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Incorrect")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { recordAnswer(isCorrect: true) }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Correct")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Tap card to reveal answer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle(folder.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $isCompleted) {
                StudyResultView(
                    folder: folder,
                    totalStudied: knowledges.count,
                    correctCount: correctCount,
                    incorrectCount: incorrectCount
                )
            }
        }
    }
    
    // MARK: - Logic
    private func recordAnswer(isCorrect: Bool) {
        guard let knowledge = currentKnowledge else { return }
        
        // update stidy record
        knowledge.reviewCount += 1
        if isCorrect {
            knowledge.correctCount += 1
            correctCount += 1
            knowledge.isMastered = true
        } else {
            incorrectCount += 1
            knowledge.isMastered = false
        }
        knowledge.lastReviewedAt = Date()
        
        // to next card
        if currentIndex + 1 < knowledges.count {
            withAnimation {
                isFlipped = false
                currentIndex += 1
            }
        } else {
            isCompleted = true
        }
    }
}

// MARK: - Subview for Card Design
private struct CardFaceView: View {
    let title: String
    let content: String
    let subHint: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)
            
            Spacer()
            
            ScrollView {
                Text(content)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Text(subHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}


#Preview {
    let folder = Folder(name: "Sample Database")
    let k1 = Knowledge(title: "SwiftUI", summary: "Declarative UI framework for iOS.")
    return FlashcardView(folder: folder, knowledges: [k1], frontKey: "Title", backKey: "Summary")
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
