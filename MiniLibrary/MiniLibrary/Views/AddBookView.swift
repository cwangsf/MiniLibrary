//
//  AddBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var totalCopies = 1
    @State private var notes = ""
    @State private var isSearching = false
    @State private var bookDescription: String?
    @State private var pageCount: Int?
    @State private var publishedDate: String?
    @State private var publisher: String?
    @State private var languageCode: String?
    @State private var coverImageURL: String?
    @State private var showingConfirmation = false

    var isButtonEnabled: Bool {
        // Allow if ISBN is provided, OR if both title and author are provided
        !isbn.isEmpty || (!title.isEmpty && !author.isEmpty)
    }

    var body: some View {
        Form {
            Section("Book Information") {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("ISBN (optional)", text: $isbn)
            }
            
            Section("Copies") {
                Stepper("Total Copies: \(totalCopies)", value: $totalCopies, in: 1...99)
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Add New Book")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if !isbn.isEmpty {
                    // If ISBN provided, search first then show confirmation
                    addBook()
                } else {
                    // If no ISBN, show confirmation directly
                    showingConfirmation = true
                }
            } label: {
                HStack {
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isSearching ? "Searching..." : "Add Book")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isButtonEnabled ? .blue : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isButtonEnabled || isSearching)
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
        }
        .sheet(isPresented: $showingConfirmation) {

            AddBookConfirmationView(
                title: title,
                author: author,
                isbn: isbn,
                totalCopies: totalCopies,
                notes: notes,
                onConfirm: insertBook
            )
        }
    }

    private func addBook() {
        // If ISBN is provided, search for book info first
        if !isbn.isEmpty {
            isSearching = true
            Task {
                do {
                    let fetchedBook = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)

                    // Update fields with fetched information
                    await MainActor.run {
                        if title.isEmpty {
                            title = fetchedBook.title
                        }
                        if author.isEmpty, let fetchedAuthor = fetchedBook.author {
                            author = fetchedAuthor
                        }
                        bookDescription = fetchedBook.bookDescription
                        pageCount = fetchedBook.pageCount
                        publishedDate = fetchedBook.publishedDate
                        publisher = fetchedBook.publisher
                        languageCode = fetchedBook.languageCode
                        coverImageURL = fetchedBook.coverImageURL

                        isSearching = false
                        showingConfirmation = true
                    }
                } catch {
                    await MainActor.run {
                        isSearching = false
                        // If search fails, still show confirmation with manual info
                        showingConfirmation = true
                    }
                }
            }
        }
    }

    private func insertBook() {
        let book = Book(
            isbn: isbn.isEmpty ? nil : isbn,
            title: title,
            author: author.isEmpty ? nil : author,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            bookDescription: bookDescription,
            pageCount: pageCount,
            publishedDate: publishedDate,
            publisher: publisher,
            languageCode: languageCode,
            coverImageURL: coverImageURL,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(book)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddBookView()
            .modelContainer(for: [Book.self])
    }
}
