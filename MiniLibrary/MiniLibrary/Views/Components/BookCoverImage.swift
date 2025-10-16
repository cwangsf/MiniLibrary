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

    var body: some View {
        Group {
            // First priority: Show cached image if available
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            // Second priority: Try to load from cache file
            else if book.cachedCoverImage != nil {
                placeholderView
                    .task {
                        await loadCachedImage()
                    }
            }
            // Third priority: Fetch and cache from API
            else {
                placeholderView
                    .task {
                        await loadCover()
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            // Cache file is missing, fetch from API
            await loadCover()
        }
    }

    /// Fetch cover from API and cache it
    private func loadCover() async {
        guard book.cachedCoverImage == nil else { return }

        await MainActor.run {
            isLoadingCover = true
        }

        await BookAPIService.shared.updateBookCover(book)

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
