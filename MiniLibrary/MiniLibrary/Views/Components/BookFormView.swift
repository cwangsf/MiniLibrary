//
//  BookFormView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang
//

import SwiftUI

/// Shared manual book entry form used in both AddBookView and the scan editing flow.
/// Handles ISBN lookup inline and calls onMetadataFetched when the API returns results.
struct BookFormView: View {
    @Binding var title: String
    @Binding var author: String
    @Binding var isbn: String
    @Binding var totalCopies: Int
    @Binding var notes: String

    var errorMessage: String? = nil
    var addButtonLabel: String = "Add Book"
    let onAdd: () -> Void
    var onMetadataFetched: ((Book) -> Void)? = nil

    @State private var isSearching = false
    @State private var lookupFailed = false

    private var canAdd: Bool {
        !isbn.isEmpty || !title.isEmpty
    }

    var body: some View {
        Form {
            if let errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.caption)
                    }
                }
            }

            Section {
                HStack {
                    TextField("ISBN (optional)", text: $isbn)
                        .keyboardType(.numberPad)
                        .onChange(of: isbn) { _, _ in lookupFailed = false }
                    if isSearching {
                        ProgressView().scaleEffect(0.8)
                    } else if !isbn.isEmpty {
                        Button {
                            lookupByISBN()
                        } label: {
                            Image(systemName: lookupFailed ? "exclamationmark.circle" : "magnifyingglass.circle.fill")
                                .foregroundStyle(lookupFailed ? .orange : .blue)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                TextField("Title", text: $title)
                TextField("Author", text: $author)
            } header: {
                Text("Book Information")
            } footer: {
                if lookupFailed {
                    Text("No book found for this ISBN. Fill in details manually.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if !isbn.isEmpty && title.isEmpty {
                    Text("Tap \(Image(systemName: "magnifyingglass.circle.fill")) to look up book info by ISBN.")
                        .font(.caption)
                }
            }

            Section("Copies") {
                Stepper("Total Copies: \(totalCopies)", value: $totalCopies, in: 1...99)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                handleAdd()
            } label: {
                HStack {
                    if isSearching {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isSearching ? "Searching..." : addButtonLabel)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background((canAdd && !isSearching) ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canAdd || isSearching)
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
        }
    }

    private func lookupByISBN() {
        guard !isbn.isEmpty else { return }
        isSearching = true
        lookupFailed = false
        Task {
            do {
                let fetched = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
                await MainActor.run {
                    if title.isEmpty { title = fetched.title }
                    if author.isEmpty, let a = fetched.author { author = a }
                    onMetadataFetched?(fetched)
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    lookupFailed = true
                }
            }
        }
    }

    private func handleAdd() {
        // Auto-fetch metadata if ISBN is given but title is still empty
        if !isbn.isEmpty && title.isEmpty {
            isSearching = true
            Task {
                do {
                    let fetched = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
                    await MainActor.run {
                        title = fetched.title
                        if author.isEmpty, let a = fetched.author { author = a }
                        onMetadataFetched?(fetched)
                        isSearching = false
                        onAdd()
                    }
                } catch {
                    await MainActor.run {
                        isSearching = false
                        onAdd()
                    }
                }
            }
        } else {
            onAdd()
        }
    }
}
