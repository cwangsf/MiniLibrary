//
//  ScanBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct ScanBookView: View {
    var scanPurpose: ScanBookViewModel.ScanPurpose
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [Book]

    @State private var viewModel = ScanBookViewModel()
    @State private var showingScanResult = false
    @State private var showingCheckoutAfterAdd = false
    @State private var showingCheckoutExisting = false
    @State private var showingReturnAfterAdd = false
    @State private var showingReturnExisting = false
    @State private var showingConfirmation = false
    @State private var bookToCheckout: Book?
    @State private var bookToReturn: Book?
    @State private var checkoutCompleted = false
    @State private var returnCompleted = false

    var navigationTitle: String {
        switch viewModel.state {
        case .confirming:
            switch scanPurpose {
            case .addBook:
                return String(localized: "Confirm Book")
            case .checkout:
                return String(localized: "Confirm Checkout")
            case .returnBook:
                return String(localized: "Confirm Return")
            }
        case .editing:
            return String(localized: "Edit Book Details")
        default:
            switch scanPurpose {
            case .addBook:
                return String(localized: "Scan Book")
            case .checkout:
                return String(localized: "Scan Book to Checkout")
            case .returnBook:
                return String(localized: "Scan Book to Return")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .scanning:
                    scannerView
                case .loading(let isbn):
                    loadingView(isbn: isbn)
                case .confirming(let book):
                    // Only show inline confirmation for addBook mode
                    // Checkout and return modes use sheet presentation
                    if scanPurpose == .addBook {
                        bookConfirmationView(book: book)
                    } else {
                        Color.clear
                    }
                case .editing, .error:
                    bookFormView
                case .existingBook:
                    Color.clear
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Don't show toolbar button in confirming state
                    if case .confirming = viewModel.state {
                        EmptyView()
                    } else {
                        Button("Cancel") {
                            if case .error = viewModel.state {
                                viewModel.reset()
                            }
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanResult) {
                if let existingBook = viewModel.existingBook {
                    ScanResultView(
                        book: existingBook,
                        scanPurpose: scanPurpose,
                        isExistingBook: true,
                        onConfirm: { copiesToAdd in
                            addCopyToExistingBook(existingBook, copies: copiesToAdd)
                        },
                        onCancel: {
                            viewModel.reset()
                        }
                    )
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .existingBook = newState {
                    showingScanResult = true
                } else if case .confirming = newState {
                    // For checkout and return modes, show confirmation as a sheet
                    if scanPurpose == .checkout || scanPurpose == .returnBook {
                        showingConfirmation = true
                    }
                }
            }
            .sheet(isPresented: $showingCheckoutAfterAdd, onDismiss: {
                viewModel.reset()
                bookToCheckout = nil
                // After sheet dismisses, check if checkout was completed
                if checkoutCompleted {
                    checkoutCompleted = false
                    dismiss()
                }
            }) {
                if let book = bookToCheckout {
                    CheckoutBookView(book: book) {
                        checkoutCompleted = true
                    }
                }
            }
            .sheet(isPresented: $showingCheckoutExisting, onDismiss: {
                viewModel.reset()
                bookToCheckout = nil
                // After sheet dismisses, check if checkout was completed
                if checkoutCompleted {
                    checkoutCompleted = false
                    dismiss()
                }
            }) {
                if let book = bookToCheckout {
                    CheckoutBookView(book: book) {
                        checkoutCompleted = true
                    }
                }
            }
            .sheet(isPresented: $showingReturnAfterAdd, onDismiss: {
                viewModel.reset()
                bookToReturn = nil
                // After sheet dismisses, check if return was completed
                if returnCompleted {
                    returnCompleted = false
                    dismiss()
                }
            }) {
                if let book = bookToReturn {
                    ReturnBookView(book: book) {
                        returnCompleted = true
                    }
                }
            }
            .sheet(isPresented: $showingReturnExisting, onDismiss: {
                viewModel.reset()
                bookToReturn = nil
                // After sheet dismisses, check if return was completed
                if returnCompleted {
                    returnCompleted = false
                    dismiss()
                }
            }) {
                if let book = bookToReturn {
                    ReturnBookView(book: book) {
                        returnCompleted = true
                    }
                }
            }
            .sheet(isPresented: $showingConfirmation) {
                showingConfirmation = false
                viewModel.reset()
            } content: {
                if case .confirming(let book) = viewModel.state {
                    bookConfirmationSheetView(book: book)
                }
            }
        }
    }

    // MARK: - Scanner View
    private var scannerView: some View {
        ZStack {
            BarcodeScannerView(
                scannedCode: Binding(
                    get: { nil },
                    set: { if let code = $0 {
                        let existing = allBooks.first(where: { $0.isbn == code })
                        viewModel.handleScannedCode(code, existingBook: existing)
                    } }
                ),
                isScanning: .constant(true)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top instructions
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)

                    Text("Point camera at ISBN barcode")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Usually found on the back cover")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.6))

                Spacer()

                // Scanning target frame in the center
                VStack {
                    Text("Position barcode here")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.bottom, 8)

                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 280, height: 120)
                        .overlay {
                            ScannerCornerBrackets()
                                .padding(8)
                        }
                }

                Spacer()

                // Bottom button
                Button("Enter ISBN Manually") {
                    viewModel.enterManualMode()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.6))
            }
        }
    }

    // MARK: - Loading View
    private func loadingView(isbn: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Fetching book information...")
                .font(.headline)

            Text("ISBN: \(isbn)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Book Confirmation Sheet View (for checkout/return modes)
    @ViewBuilder
    private func bookConfirmationSheetView(book: Book) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    BookCoverImage(book: book, width: 180, height: 270)
                        .padding(.top, 20)

                    // Book Info
                    VStack(alignment: .center, spacing: 8) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let author = book.author {
                            Text(author)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        if let isbn = book.isbn {
                            Text("ISBN: \(isbn)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Message
                    VStack(spacing: 8) {
                        Text("Book not in catalog")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Add this book to your catalog first")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Book Not Found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingConfirmation = false
                        viewModel.reset()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        if scanPurpose == .checkout {
                            addBookAndProceedToCheckout()
                            showingConfirmation = false
                        } else if scanPurpose == .returnBook {
                            addBookAndProceedToReturn()
                            showingConfirmation = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Book to Catalog")
                        }
                        .prominentButton(color: .green)
                    }

                    Button {
                        showingConfirmation = false
                        viewModel.reset()
                    } label: {
                        Text("Cancel")
                            .secondaryButton()
                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Book Confirmation View
    private func bookConfirmationView(book: Book) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover
                BookCoverImage(book: book, width: 180, height: 270)
                    .padding(.top, 20)

                // Book Info
                VStack(alignment: .center, spacing: 8) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let author = book.author {
                        Text(author)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let isbn = book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let publisher = book.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let publishedDate = book.publishedDate {
                        Text("Published: \(publishedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

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

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                switch scanPurpose {
                case .addBook:
                    Button {
                        addBook()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm & Add Book")
                        }
                        .prominentButton(color: .green)
                    }

                    Button {
                        viewModel.confirmBook()
                    } label: {
                        Text("Edit Details")
                            .secondaryButton()
                    }

                case .checkout:
                    // Check if book exists in catalog
                    let existingBook = viewModel.existingBook ?? allBooks.first(where: { $0.isbn == book.isbn })
                    
                    if let existingBookForCheckout = existingBook {
                        // Book exists - allow checkout
                        Button {
                            bookToCheckout = existingBookForCheckout
                            showingCheckoutExisting = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Proceed to Checkout")
                            }
                            .prominentButton(color: .blue)
                        }
                    } else {
                        // Book not in catalog - only allow adding
                        VStack(spacing: 8) {
                            Text("Book not in catalog")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                addBookAndProceedToCheckout()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Book to Catalog")
                                }
                                .prominentButton(color: .green)
                            }
                        }
                    }

                case .returnBook:
                    // Check if book exists in catalog
                    let existingBook = viewModel.existingBook ?? allBooks.first(where: { $0.isbn == book.isbn })
                    
                    if let existingBookForReturn = existingBook {
                        // Book exists - allow return
                        Button {
                            bookToReturn = existingBookForReturn
                            showingReturnExisting = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Proceed to Return")
                            }
                            .prominentButton(color: .blue)
                        }
                    } else {
                        // Book not in catalog - only allow adding
                        VStack(spacing: 8) {
                            Text("Book not in catalog")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                addBookAndProceedToReturn()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Book to Catalog")
                                }
                                .prominentButton(color: .green)
                            }
                        }
                    }
                }

                Button {
                    viewModel.reset()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
        }
    }

    // MARK: - Book Form View
    private var bookFormView: some View {
        Form {
            if case .error(let message) = viewModel.state {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.caption)
                    }
                }
            }

            Section("Book Information") {
                TextField("Title", text: $viewModel.title)
                TextField("Author", text: $viewModel.author)
                TextField("ISBN", text: $viewModel.isbn)
            }

            Section("Copies") {
                Stepper("Total Copies: \(viewModel.totalCopies)", value: $viewModel.totalCopies, in: 1...99)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                addBook()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Book")
                }
                .prominentButton(color: (viewModel.title.isEmpty || viewModel.author.isEmpty) ? .gray : .blue)
            }
            .disabled(viewModel.title.isEmpty || viewModel.author.isEmpty)
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
        }
    }

    // MARK: - Actions
    
    /// Creates a new Book from the current ViewModel state
    /// Handles three scenarios: confirming scanned data, editing scanned data, or manual entry
    private func createBookFromViewModel() -> Book {
        // If we have scanned book data, use it as the base
        if let scannedBook = viewModel.scannedBook {
            // Check if user is confirming unedited data or has entered edit mode
            if case .confirming = viewModel.state {
                // Confirming mode: use scanned data directly with default 1 copy
                return Book(
                    isbn: scannedBook.isbn,
                    title: scannedBook.title,
                    author: scannedBook.author,
                    totalCopies: 1,
                    availableCopies: 1,
                    bookDescription: scannedBook.bookDescription,
                    pageCount: scannedBook.pageCount,
                    publishedDate: scannedBook.publishedDate,
                    publisher: scannedBook.publisher,
                    languageCode: scannedBook.languageCode,
                    coverImageURL: scannedBook.coverImageURL
                )
            } else {
                // Editing mode: use edited values from viewModel, preserve scanned metadata
                return Book(
                    isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
                    title: viewModel.title,
                    author: viewModel.author,
                    totalCopies: viewModel.totalCopies,
                    availableCopies: viewModel.totalCopies,
                    bookDescription: scannedBook.bookDescription,
                    pageCount: scannedBook.pageCount,
                    publishedDate: scannedBook.publishedDate,
                    publisher: scannedBook.publisher,
                    languageCode: scannedBook.languageCode,
                    coverImageURL: scannedBook.coverImageURL
                )
            }
        } else {
            // Manual entry: create book from form fields only (no scanned data)
            return Book(
                isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
                title: viewModel.title,
                author: viewModel.author,
                totalCopies: viewModel.totalCopies,
                availableCopies: viewModel.totalCopies
            )
        }
    }
    
    private func addBook() {
        let book = createBookFromViewModel()
        modelContext.insert(book)
        viewModel.reset()
        dismiss()
    }

    private func addCopyToExistingBook(_ book: Book, copies: Int) {
        book.totalCopies += copies
        book.availableCopies += copies

        showingScanResult = false
        viewModel.reset()
    }
    
    private func addBookAndProceedToCheckout() {
        let book = createBookFromViewModel()
        modelContext.insert(book)
        
        // Proceed to checkout with the newly added book
        bookToCheckout = book
        showingCheckoutAfterAdd = true
    }
    
    private func addBookAndProceedToReturn() {
        let book = createBookFromViewModel()
        modelContext.insert(book)
        
        // Proceed to return with the newly added book
        bookToReturn = book
        showingReturnAfterAdd = true
    }
}

#Preview {
    ScanBookView(scanPurpose: .addBook)
        .modelContainer(for: [Book.self])
}
