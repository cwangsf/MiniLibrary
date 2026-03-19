//
//  BookDetailView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
import UIKit
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "BookDetailView")

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
    @State private var checkoutToReturn: CheckoutRecord?
    @State private var isFetchingBookInfo = false
    @State private var isEditingInfo = false
    @State private var titleText = ""
    @State private var authorText = ""
    @State private var isbnText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover - Use Google Books fallback if no cached cover
                bookCoverView
                    .padding(.top, 20)
                
                // Book Info
                VStack(alignment: .center, spacing: 8) {
                    HStack {
                        Spacer()
                        Button(isEditingInfo ? "Done" : "Edit") {
                            if isEditingInfo {
                                saveBookInfo()
                            }
                            isEditingInfo.toggle()
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    
                    if isEditingInfo {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Book Title", text: $titleText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Author")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("Author Name", text: $authorText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ISBN")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("ISBN", text: $isbnText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        BookInfoHeaderView(book: book)
                    }
                }
                
                // Checkout Button
                if book.availableCopies >= 1 {
                    Button {
                        showingCheckoutSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Check Out Book")
                        }
                        .prominentButton(color: .blue)
                    }
                    .padding(.horizontal)
                }
                
                // Return Book Buttons
                if let checkouts = book.checkouts?.filter({ $0.isActive && !$0.isDeleted }), !checkouts.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(checkouts) { checkout in
                            Button {
                                // Validate checkout and related objects before showing confirmation
                                guard !checkout.isDeleted,
                                      let student = checkout.student, !student.isDeleted else {
                                    logger.warning("Attempted to return book with deleted checkout or student")
                                    return
                                }
                                checkoutToReturn = checkout
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.left.circle.fill")
                                    HStack {
                                        Text("Return Book")
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("Student: \(checkout.student?.fullName ?? "Unknown")")
                                            .font(.caption)
                                    }
                                }
                                .prominentButton(color: .green)
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
                                Text(checkout.student?.fullName ?? "Unknown")
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
                        if let amazonURL = book.amazonURL() {
                            Link(destination: amazonURL) {
                                HStack {
                                    Image(systemName: "cart.fill")
                                    Text("Find on Amazon")
                                }
                                .prominentButton(color: .orange)
                            }
                        }
                    } else {
                        // For catalog items - link to Google Books
                        if let googleBooksURL = book.googleBooksURL() {
                            Link(destination: googleBooksURL) {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("View on Google Books")
                                }
                                .prominentButton(color: .blue.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal)
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
        .sheet(isPresented: $showingCheckoutSheet) {
            CheckoutBookView(book: book, onCheckoutComplete: {
                // Dismiss the detail view after checkout
                dismiss()
            })
        }
        .sheet(item: $checkoutToReturn) { checkout in
            ReturnConfirmationView(
                book: book,
                checkout: checkout,
                onConfirm: {
                    returnBook(checkout)
                    checkoutToReturn = nil
                }
            )
        }
        .onAppear {
            notesText = book.notes ?? ""
            totalCopiesText = "\(book.totalCopies)"
            availableCopiesText = "\(book.availableCopies)"
            titleText = book.title
            authorText = book.author ?? ""
            isbnText = book.isbn ?? ""
            
            // Fetch book info in background if missing metadata
            fetchBookInfoIfNeeded()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Book Cover View
    
    @ViewBuilder
    private var bookCoverView: some View {
        if book.cachedCoverImage == nil,
           let coverURL = book.coverImageURL,
           let url = URL(string: coverURL) {
            // Fallback to Google Books cover using AsyncImage
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // Loading placeholder
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(width: 180, height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onAppear {
                        logger.info("Loading Google Books cover for '\(book.title)' from URL: \(url.absoluteString)")
                    }
                    
                case .success(let image):
                    // Successfully loaded Google Books cover
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 270)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .task {
                            logger.info("Successfully loaded Google Books cover for '\(book.title)'")
                            // Cache the image so it appears in list view
                            await cacheGoogleBooksCover(from: url)
                        }
                    
                case .failure(let error):
                    // Failed to load - show placeholder
                    BookCoverImage(book: book, width: 180, height: 270)
                        .onAppear {
                            logger.warning("Failed to load Google Books cover for '\(book.title)': \(error.localizedDescription)")
                        }
                    
                @unknown default:
                    BookCoverImage(book: book, width: 180, height: 270)
                }
            }
        } else {
            // No cover available - show placeholder
            BookCoverImage(book: book, width: 180, height: 270)
        }
    }
    
    private func returnBook(_ checkout: CheckoutRecord) {
        BookManagementService.returnBook(checkout, modelContext: modelContext)
    }
    
    private func cacheGoogleBooksCover(from url: URL) async {
        do {
            // Download the image data
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Validate it's a valid image
            guard UIImage(data: data) != nil else {
                logger.warning("Downloaded data from Google Books is not a valid image for '\(book.title)'")
                return
            }
            
            // Save to cache
            if let filename = try await ImageCacheService.shared.saveImageData(data, for: book.id.uuidString) {
                await MainActor.run {
                    book.cachedCoverImage = filename
                    logger.info("Successfully cached Google Books cover for '\(book.title)' as '\(filename)'")
                }
            }
        } catch {
            logger.error("Failed to cache Google Books cover for '\(book.title)': \(error.localizedDescription)")
        }
    }
    
    private func saveNotes() {
        book.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func saveBookInfo() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = authorText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedISBN = isbnText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't allow empty title
        guard !trimmedTitle.isEmpty else {
            titleText = book.title
            authorText = book.author ?? ""
            isbnText = book.isbn ?? ""
            return
        }
        
        book.title = trimmedTitle
        book.author = trimmedAuthor.isEmpty ? nil : trimmedAuthor
        book.isbn = trimmedISBN.isEmpty ? nil : trimmedISBN
        
        // Save changes to database
        do {
            try modelContext.save()
            logger.info("Successfully saved book info for '\(book.title)'")
        } catch {
            logger.error("Failed to save book info: \(error.localizedDescription)")
        }
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
        
        // Calculate how many copies were added
        let copiesDifference = totalCopies - book.totalCopies
        
        book.totalCopies = totalCopies
        
        // If total copies increased, add those new copies to available
        if copiesDifference > 0 {
            book.availableCopies = availableCopies + copiesDifference
        } else {
            book.availableCopies = availableCopies
        }
        
        // Save changes to database
        do {
            try modelContext.save()
            logger.info("Successfully saved copy counts for '\(book.title)': total=\(totalCopies), available=\(book.availableCopies)")
        } catch {
            logger.error("Failed to save copy counts: \(error.localizedDescription)")
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
                        author: book.author ?? ""
                    )
                    
                    guard let firstItem = items.first else {
                        isFetchingBookInfo = false
                        return
                    }
                    
                    fetchedBook = BookAPIService.shared.createBookFromSearchResult(firstItem)
                }
                
                // Update the existing book with fetched metadata
                await MainActor.run {
                    updateBookMetadata(from: fetchedBook)
                    isFetchingBookInfo = false
                }
            } catch {
                // Silently fail - this is a background enhancement
                logger.error("Failed to fetch book info: \(error.localizedDescription)")
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

#Preview {
    BookDetailView(book: Book(
        isbn: "9780439708180",
        title: "Harry Potter and the Sorcerer's Stone",
        author: "J.K. Rowling",
        totalCopies: 3,
        publishedDate: "1998-09-01",
        publisher: "Scholastic"
    ))
}
