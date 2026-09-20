//
//  CardConfigView.swift
//  Cardabase
//
//  Created by Kenichiro Suzuki on 2026/07/31.
//

import SwiftUI
import SwiftData

struct CardConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var folder: Folder
    
    // MARK: - State Management
    @State private var selectedFrontKey: String = "Title"
    @State private var selectedBackKey: String = "Summary"
    @State private var onlyUnmastered: Bool = false
    @State private var shuffleCards: Bool = true
    @State private var isShowingFlashcard: Bool = false
    @State private var preparedKnowledges: [Knowledge] = []
    
    private var currentTargetKnowledges: [Knowledge] {
        var list = folder.knowledges
        if onlyUnmastered {
            list = list.filter { $0.masterStatus != .mastered }
        }
        return list
    }
    
    // MARK: - Main Body
    var body: some View {
        NavigationStack {
            Form {
                // Field Mapping Section
                Section(header: Text("Card Mapping"), footer: Text("Select which field to display on the front and back of the flashcard.")) {
                    Picker("Front (Question)", selection: $selectedFrontKey) {
                        ForEach(folder.availableFieldKeys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    
                    Picker("Back (Answer)", selection: $selectedBackKey) {
                        ForEach(folder.availableFieldKeys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                }
                
                // Study Options Section
                Section(header: Text("Study Options")) {
                    Toggle("Only Unmastered Cards", isOn: $onlyUnmastered)
                    Toggle("Shuffle Cards", isOn: $shuffleCards)
                }
                
                // Start Study Button Section
                Section {
                    Button(action: startStudy) {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                            Text("Start Study (\(currentTargetKnowledges.count) Cards)")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(currentTargetKnowledges.isEmpty)
                }
            }
            .navigationTitle("Study Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                selectedFrontKey = folder.defaultFrontKey
                selectedBackKey = folder.defaultBackKey
            }
            .fullScreenCover(isPresented: $isShowingFlashcard) {
                FlashcardView(
                    folder: folder,
                    knowledges: preparedKnowledges,
                    frontKey: selectedFrontKey,
                    backKey: selectedBackKey,
                    onDone: { dismiss() }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func startStudy() {
        folder.defaultFrontKey = selectedFrontKey
        folder.defaultBackKey = selectedBackKey
        
        var list = folder.knowledges
        if onlyUnmastered {
            list = list.filter { $0.masterStatus != .mastered }
        }
        
        if shuffleCards {
            preparedKnowledges = list.shuffled()
        } else {
            preparedKnowledges = list.sorted { $0.createdAt > $1.createdAt }
        }
        
        isShowingFlashcard = true
    }
}

// MARK: - Preview

#Preview {
    let folder = Folder(name: "SAKE DIPLOMA Prep")
    folder.knowledges.append(Knowledge(title: "Yamada Nishiki", summary: "King of Sake Rice produced mainly in Hyogo Pref."))
    return CardConfigView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
