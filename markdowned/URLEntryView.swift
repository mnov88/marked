//
//  URLEntryView.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import SwiftUI

struct URLEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = "https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32016R0679&qid=1763302829404"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    let onDocumentLoaded: (Document) -> Void
    
    private let contentLoader = ContentLoader()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter URL", text: $urlString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .disabled(isLoading)
                } header: {
                    Text("Web Page URL")
                } footer: {
                    Text("Enter a URL to download and convert HTML content to readable text")
                }
                
                Section {
                    Button(action: loadContent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isLoading ? "Loading..." : "Load Content")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(urlString.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error Loading Content", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    @MainActor
    private func loadContent() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let document = try await contentLoader.loadContent(from: urlString)
                onDocumentLoaded(document)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    URLEntryView { doc in
        print("Loaded: \(doc.title)")
    }
}

