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

    var body: some View {
        Group {
            if let coverURL = book.coverImageURL,
               let secureURL = secureURL(from: coverURL),
               let url = URL(string: secureURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
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

    private func loadCover() async {
        guard book.coverImageURL == nil else { return }

        isLoadingCover = true
        await BookAPIService.shared.updateBookCover(book)
        isLoadingCover = false
    }

    /// Convert HTTP URLs to HTTPS for App Transport Security
    private func secureURL(from urlString: String) -> String? {
        if urlString.hasPrefix("http://") {
            return urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        return urlString
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
