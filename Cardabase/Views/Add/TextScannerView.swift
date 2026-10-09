//
//  TextScannerView.swift
//  Cardabase
//

import SwiftUI
import Vision
import VisionKit
import PhotosUI

/// Camera OCR and Image Picker Text Recognizer View
struct TextScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// Closure triggered when user selects recognized text snippets
    let onTextSelected: (String) -> Void
    
    @State private var recognizedTextItems: [String] = []
    @State private var isProcessingImage: Bool = false
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    
    // Camera availability check
    private var isDataScannerSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isDataScannerSupported {
                    // Live Camera OCR View
                    DataScannerRepresentable(recognizedTextItems: $recognizedTextItems)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                } else {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "camera.metering.unknown",
                        description: Text("Live camera text scanning is not available on this device or simulator.")
                    )
                    .frame(height: 240)
                }
                
                // Photo Library Picker Option
                PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Select Photo from Library")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedPhotosPickerItem) { _, newItem in
                    Task {
                        await processSelectedPhoto(newItem)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Scanned Results List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recognized Text Snippets")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isProcessingImage {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.horizontal)
                    
                    if recognizedTextItems.isEmpty {
                        ContentUnavailableView(
                            "No Text Detected",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Point camera at text or select an image from your library.")
                        )
                    } else {
                        List {
                            ForEach(recognizedTextItems, id: \.self) { text in
                                Button(action: {
                                    onTextSelected(text)
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(text)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Camera OCR Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Recognizes text from static photo selected via PhotosPicker
    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run { isProcessingImage = true }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data),
           let cgImage = uiImage.cgImage {
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                let extractedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                Task { @MainActor in
                    self.recognizedTextItems = extractedStrings
                    self.isProcessingImage = false
                }
            }
            
            request.recognitionLevel = .accurate
            try? requestHandler.perform([request])
        } else {
            await MainActor.run { isProcessingImage = false }
        }
    }
}

// MARK: - UIViewControllerRepresentable for DataScannerViewController

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedTextItems: [String]
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerRepresentable
        
        init(_ parent: DataScannerRepresentable) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateTextItems(from: allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateTextItems(from: allItems)
        }
        
        private func updateTextItems(from items: [RecognizedItem]) {
            let texts = items.compactMap { item -> String? in
                if case .text(let text) = item {
                    return text.transcript
                }
                return nil
            }
            
            Task { @MainActor in
                self.parent.recognizedTextItems = Array(Set(texts)).sorted()
            }
        }
    }
}

// MARK: - Preview
#Preview("Text Scanner Preview") {
    TextScannerView { selectedText in
        print("Selected Text: \(selectedText)")
    }
}
