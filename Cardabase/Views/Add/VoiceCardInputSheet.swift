//
//  VoiceCardInputSheet.swift
//  Cardabase
//

import SwiftUI
import SwiftData

struct VoiceCardInputSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    let folder: Folder
    
    @StateObject private var voiceManager = VoiceInputManager()
    
    @State private var parsedResult = ParsedVoiceResult()
    @State private var isPermissionDenied: Bool = false
    
    private var isSaveDisabled: Bool {
        parsedResult.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        Limits.isKnowledgeLimitReached(currentCountInFolder: folder.knowledges.count, isPro: appState.isProUser)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 音声入力波形＆テキストリアルタイム表示エリア
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(voiceManager.isRecording ? Color.red.opacity(0.15) : Color.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: voiceManager.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(voiceManager.isRecording ? .red : Color.accentColor)
                            .symbolEffect(.variableColor.iterative.reversing, isActive: voiceManager.isRecording)
                    }
                    
                    Text(voiceManager.isRecording ? "Listening..." : "Tap & Hold or Speak")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    if !voiceManager.transcribedText.isEmpty {
                        Text("“\(voiceManager.transcribedText)”")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 解析されたカードプレビュー兼編集エリア
                Form {
                    Section(header: Text("Parsed Card Preview")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextField("Title", text: $parsedResult.title)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Summary")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $parsedResult.summary)
                                .frame(minHeight: 60)
                        }
                    }
                    
                    if !parsedResult.customFields.isEmpty {
                        Section(header: Text("Custom Fields")) {
                            ForEach($parsedResult.customFields) { $field in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(field.key)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Value", text: $field.value)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Voice to Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        voiceManager.stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .bold()
                    .disabled(isSaveDisabled)
                }
            }
            .task {
                let granted = await voiceManager.requestPermissions()
                if granted {
                    voiceManager.startRecording()
                } else {
                    isPermissionDenied = true
                }
            }
            .onChange(of: voiceManager.transcribedText) { _, newText in
                self.parsedResult = VoiceParser.parse(text: newText, folder: folder)
            }
            .alert("Permission Denied", isPresented: $isPermissionDenied) {
                Button("OK") { dismiss() }
            } message: {
                Text("Speech Recognition and Microphone permissions are required to use Voice to Card.")
            }
        }
    }
    
    private func saveCard() {
        voiceManager.stopRecording()
        
        let trimmedTitle = parsedResult.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let knowledge = Knowledge(
            title: trimmedTitle,
            summary: parsedResult.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            customFields: parsedResult.customFields
        )
        knowledge.folder = folder
        folder.knowledges.append(knowledge)
        
        dismiss()
    }
}

// MARK: - Preview
#Preview("Voice to Card Input") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Knowledge.self, configurations: config)
    
    let folder = Folder(
        name: "Financial Indicators",
        customFieldSchemas: [
            FieldSchema(key: "Formula", type: .text),
            FieldSchema(key: "Benchmark", type: .text)
        ]
    )
    container.mainContext.insert(folder)
    
    return VoiceCardInputSheet(folder: folder)
        .environmentObject(AppState())
        .modelContainer(container)
}
