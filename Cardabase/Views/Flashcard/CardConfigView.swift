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
    
    // State management
    @State private var selectedFrontKey: String = "Title"
    @State private var selectedBackKey: String = "Summary"
    @State private var onlyUnmastered: Bool = false
    @State private var shuffleCards: Bool = true
    @State private var isShowingFlashcard: Bool = false
    
    // calculate card list
    private var targetKnowledges: [Knowledge] {
        var list = folder.knowledges
        if onlyUnmastered {
            // 修正: .mastered 以外のカード（.unreviewed および .incorrect）を抽出
            list = list.filter { $0.masterStatus != .mastered }
        }
        if shuffleCards {
            return list.shuffled()
        } else {
            return list.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // field mapping
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
                
                // study options
                Section(header: Text("Study Options")) {
                    Toggle("Only Unmastered Cards", isOn: $onlyUnmastered)
                    Toggle("Shuffle Cards", isOn: $shuffleCards)
                }
                
                // start button
                Section {
                    Button(action: {
                        folder.defaultFrontKey = selectedFrontKey
                        folder.defaultBackKey = selectedBackKey
                        isShowingFlashcard = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                            Text("Start Study (\(targetKnowledges.count) Cards)")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(targetKnowledges.isEmpty)
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
                    knowledges: targetKnowledges,
                    frontKey: selectedFrontKey,
                    backKey: selectedBackKey,
                    onDone: {
                        dismiss()
                    }
                )
            }
        }
    }
}

#Preview {
    let folder = Folder(name: "Sample Database")
    folder.knowledges.append(Knowledge(title: "Swift", summary: "Apple's programming language."))
    return CardConfigView(folder: folder)
        .modelContainer(for: [Folder.self, Knowledge.self], inMemory: true)
}
