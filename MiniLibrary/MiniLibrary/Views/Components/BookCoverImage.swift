//
//  BookCoverImage.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct BookCoverImage: View {
    let book: Book
    let width: CGFloat
    let height: CGFloat

    @State private var isLoadingCover = false
    @State private var cachedImage: UIImage?
    @State private var loadTask: Task<Void, Never>?
    @State private var hasAttemptedLoad = false

    var body: some View {
        ZStack {
            // Always show placeholder as background
            placeholderView
            
            // Overlay the actual image if loaded
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            // Only try to load once
            guard !hasAttemptedLoad else { return }
            hasAttemptedLoad = true
            
            // Use background task with low priority to not block scrolling
            loadTask = Task(priority: .utility) {
                if book.cachedCoverImage != nil {
                    await loadCachedImage()
                } else {
                    await loadCover()
                }
            }
        }
        .onDisappear {
            // Cancel loading when scrolled off screen
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private var placeholderView: some View {
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
                    .font(.system(size: width * 0.3))
                    .foregroundStyle(.white.opacity(0.8))

                if isLoadingCover {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }

    /// Load cached image from disk
    private func loadCachedImage() async {
        guard let filename = book.cachedCoverImage else { return }

        if let imageData = await ImageCacheService.shared.loadImage(for: filename),
           let image = UIImage(data: imageData) {
            await MainActor.run {
                self.cachedImage = image
            }
        } else {
            // Cache file is missing, clear the cached path and fetch from API
            await MainActor.run {
                book.cachedCoverImage = nil
            }
            await loadCover()
        }
    }

    /// Fetch cover from API and cache it
    private func loadCover() async {
        // Don't try if we already have a cached image loaded
        guard cachedImage == nil else { return }

        await MainActor.run {
            isLoadingCover = true
        }

        // Check if task was cancelled before making network request
        guard !Task.isCancelled else {
            await MainActor.run {
                isLoadingCover = false
            }
            return
        }

        await BookAPIService.shared.updateBookCover(book)

        // Check again after network request
        guard !Task.isCancelled else {
            await MainActor.run {
                isLoadingCover = false
            }
            return
        }

        // After fetching, try to load the cached image
        if let filename = book.cachedCoverImage {
            if let imageData = await ImageCacheService.shared.loadImage(for: filename),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    self.cachedImage = image
                }
            }
        }

        await MainActor.run {
            isLoadingCover = false
        }
    }
}

#Preview {
    BookCoverImage(
        book: Book(
            title: "Sample Book",
            author: "Author Name",
            totalCopies: 1
        ),
        width: 80,
        height: 120
    )
}
