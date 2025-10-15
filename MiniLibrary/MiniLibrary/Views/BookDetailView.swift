//
//  BookDetailView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckoutSheet = false
    @State private var isEditingNotes = false
    @State private var notesText = ""
    @State private var isEditingCopies = false
    @State private var totalCopiesText = ""
    @State private var availableCopiesText = ""
    @State private var showingReturnConfirmation = false
    @State private var checkoutToReturn: CheckoutRecord?
    @State private var isFetchingBookInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover - Centered at top
                BookCoverImage(book: book, width: 180, height: 270)
                    .padding(.top, 20)

                // Book Info
                BookInfoHeaderView(book: book)

                // Book Description
                if let description = book.bookDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // External Links
                VStack(spacing: 12) {
                    if book.isWishlistItem {
                        // For wishlist items - link to Amazon
                        if let amazonURL = generateAmazonURL() {
                            Link(destination: amazonURL) {
                                HStack {
                                    Image(systemName: "cart.fill")
                                    Text("Find on Amazon")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        // For catalog items - link to Google Books
                        if let googleBooksURL = generateGoogleBooksURL() {
                            Link(destination: googleBooksURL) {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("View on Google Books")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Checkout Button
                if book.availableCopies >= 1 {
                    Button {
                        showingCheckoutSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Check Out Book")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                // Return Book Buttons
                if let checkouts = book.checkouts?.filter({ $0.isActive }), !checkouts.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(checkouts) { checkout in
                            Button {
                                checkoutToReturn = checkout
                                showingReturnConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.left.circle.fill")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Return Book")
                                            .fontWeight(.medium)
                                        Text("Student: \(checkout.student?.libraryId ?? "Unknown")")
                                            .font(.caption)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Availability
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Availability")
                            .font(.headline)
                        Spacer()
                        Button(isEditingCopies ? "Done" : "Edit") {
                            if isEditingCopies {
                                saveCopies()
                            } else {
                                startEditingCopies()
                            }
                            isEditingCopies.toggle()
                        }
                        .font(.subheadline)
                    }

                    if isEditingCopies {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Copies:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Total", text: $totalCopiesText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack {
                                Text("Available:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Available", text: $availableCopiesText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("Note: Available copies cannot exceed total copies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Label("\(book.availableCopies) available", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(book.availableCopies > 0 ? .green : .red)

                            Spacer()

                            Text("of \(book.totalCopies) total")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Active Checkouts
                if let checkouts = book.checkouts?.filter({ $0.isActive }), !checkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Checked Out By")
                            .font(.headline)

                        ForEach(checkouts) { checkout in
                            HStack {
                                Text(checkout.student?.libraryId ?? "Unknown")
                                    .font(.subheadline)

                                Spacer()

                                Text("Due: \(checkout.dueDate, format: .dateTime.month().day())")
                                    .font(.caption)
                                    .foregroundStyle(checkout.isOverdue ? .red : .secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        Spacer()
                        Button(isEditingNotes ? "Done" : "Edit") {
                            if isEditingNotes {
                                saveNotes()
                            }
                            isEditingNotes.toggle()
                        }
                        .font(.subheadline)
                    }

                    if isEditingNotes {
                        TextEditor(text: $notesText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        if let notes = book.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        } else {
                            Text("No notes yet. Tap Edit to add notes.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    book.isFavorite.toggle()
                } label: {
                    Image(systemName: book.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(book.isFavorite ? .red : .gray)
                }
            }
        }
        .sheet(isPresented: $showingCheckoutSheet) {
            CheckoutBookView(book: book, onCheckoutComplete: {
                // Dismiss the detail view after checkout
                dismiss()
            })
        }
        .sheet(isPresented: $showingReturnConfirmation) {
            if let checkout = checkoutToReturn {
                ReturnConfirmationView(
                    book: book,
                    checkout: checkout,
                    onConfirm: {
                        returnBook(checkout)
                    }
                )
            }
        }
        .onAppear {
            notesText = book.notes ?? ""
            totalCopiesText = "\(book.totalCopies)"
            availableCopiesText = "\(book.availableCopies)"

            // Fetch book info in background if missing metadata
            fetchBookInfoIfNeeded()
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1

            // Log activity
            let activity = Activity(
                type: .return,
                bookTitle: book.title,
                bookAuthor: book.author,
                studentLibraryId: checkout.student?.libraryId,
                additionalInfo: nil
            )
            modelContext.insert(activity)
        }
    }

    private func saveNotes() {
        book.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func startEditingCopies() {
        totalCopiesText = "\(book.totalCopies)"
        availableCopiesText = "\(book.availableCopies)"
    }

    private func saveCopies() {
        guard let totalCopies = Int(totalCopiesText),
              let availableCopies = Int(availableCopiesText),
              totalCopies > 0,
              availableCopies >= 0,
              availableCopies <= totalCopies else {
            // Invalid input, reset to current values
            totalCopiesText = "\(book.totalCopies)"
            availableCopiesText = "\(book.availableCopies)"
            return
        }

        book.totalCopies = totalCopies
        book.availableCopies = availableCopies
    }

    private func generateGoogleBooksURL() -> URL? {
        if let isbn = book.isbn {
            // Use ISBN for most accurate results
            return URL(string: "https://books.google.com/books?isbn=\(isbn)")
        } else {
            // Fallback to title and author search
            let query = "\(book.title) \(book.author)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://books.google.com/books?q=\(query)")
        }
    }

    private func generateAmazonURL() -> URL? {
        if let isbn = book.isbn {
            // Use ISBN for most accurate results
            return URL(string: "https://www.amazon.com/s?k=\(isbn)")
        } else {
            // Fallback to title and author search
            let query = "\(book.title) \(book.author)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://www.amazon.com/s?k=\(query)")
        }
    }

    private func fetchBookInfoIfNeeded() {
        // Only fetch if we're missing key metadata and not already fetching
        guard !isFetchingBookInfo else { return }

        // Check if we need to fetch (missing description or other metadata)
        let needsFetch = book.bookDescription == nil ||
                        book.bookDescription?.isEmpty == true ||
                        book.coverImageURL == nil

        guard needsFetch else { return }

        // We need an ISBN or at least title to search
        guard book.isbn != nil || !book.title.isEmpty else { return }

        isFetchingBookInfo = true

        Task {
            do {
                let fetchedBook: Book

                if let isbn = book.isbn {
                    // Fetch by ISBN for most accurate results
                    fetchedBook = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
                } else {
                    // Fallback to title/author search
                    let items = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                        title: book.title,
                        author: book.author
                    )

                    guard let firstItem = items.first else {
                        isFetchingBookInfo = false
                        return
                    }

                    fetchedBook = await BookAPIService.shared.createBookFromSearchResult(firstItem)
                }

                // Update the existing book with fetched metadata
                await MainActor.run {
                    updateBookMetadata(from: fetchedBook)
                    isFetchingBookInfo = false
                }
            } catch {
                // Silently fail - this is a background enhancement
                print("Failed to fetch book info: \(error.localizedDescription)")
                await MainActor.run {
                    isFetchingBookInfo = false
                }
            }
        }
    }

    private func updateBookMetadata(from fetchedBook: Book) {
        // Update metadata fields, but preserve user data and inventory
        if book.bookDescription == nil || book.bookDescription?.isEmpty == true {
            book.bookDescription = fetchedBook.bookDescription
        }

        if book.coverImageURL == nil {
            book.coverImageURL = fetchedBook.coverImageURL
        }

        if book.pageCount == nil {
            book.pageCount = fetchedBook.pageCount
        }

        if book.publishedDate == nil {
            book.publishedDate = fetchedBook.publishedDate
        }

        if book.publisher == nil {
            book.publisher = fetchedBook.publisher
        }

        if book.languageCode == nil {
            book.languageCode = fetchedBook.languageCode
        }

        // Don't update: title, author, ISBN, totalCopies, availableCopies, notes, checkouts
        // These are user-managed or critical data
    }
}
