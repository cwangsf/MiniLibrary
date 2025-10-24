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
                addBook()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Book")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background((title.isEmpty || author.isEmpty) ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(title.isEmpty || author.isEmpty)
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func addBook() {
        let book = Book(
            isbn: isbn.isEmpty ? nil : isbn,
            title: title,
            author: author,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(book)

        // Log activity
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(totalCopies) \(totalCopies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddBookView()
            .modelContainer(for: [Book.self])
    }
}
