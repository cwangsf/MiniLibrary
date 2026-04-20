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
    @State private var showingConfirmation = false

    // Metadata populated by ISBN lookup or carried through to the inserted book
    @State private var bookDescription: String?
    @State private var pageCount: Int?
    @State private var publishedDate: String?
    @State private var publisher: String?
    @State private var languageCode: String?
    @State private var coverImageURL: String?

    var body: some View {
        BookFormView(
            title: $title,
            author: $author,
            isbn: $isbn,
            totalCopies: $totalCopies,
            notes: $notes,
            onAdd: { showingConfirmation = true },
            onMetadataFetched: { fetched in
                bookDescription = fetched.bookDescription
                pageCount = fetched.pageCount
                publishedDate = fetched.publishedDate
                publisher = fetched.publisher
                languageCode = fetched.languageCode
                coverImageURL = fetched.coverImageURL
            }
        )
        .navigationTitle("Add New Book")
        .navigationBarTitleDisplayMode(.inline)
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

    private func insertBook() {
        let resolvedTitle = title.isEmpty ? (isbn.isEmpty ? "Unknown Title" : "ISBN: \(isbn)") : title
        let book = Book(
            isbn: isbn.isEmpty ? nil : isbn,
            title: resolvedTitle,
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
