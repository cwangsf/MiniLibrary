//
//  ImageCacheService.swift
//  MiniLibrary
//
//  Created by Claude on 10/16/25.
//

import Foundation
import UIKit

/// Service for caching book cover images to disk
actor ImageCacheService {
    static let shared = ImageCacheService()

    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL? = {
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let bookCoversDirectory = cachesDirectory.appendingPathComponent("BookCovers", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: bookCoversDirectory.path) {
            try? fileManager.createDirectory(at: bookCoversDirectory, withIntermediateDirectories: true)
        }

        return bookCoversDirectory
    }()

    private init() {}

    // MARK: - Public Methods

    /// Download and cache an image from URL
    /// Returns the local file path if successful
    func cacheImage(from urlString: String, for bookId: String) async throws -> String? {
        // Ensure we have a valid URL
        guard let url = URL(string: urlString) else {
            return nil
        }

        // Download the image
        let (data, _) = try await URLSession.shared.data(from: url)

        // Verify it's a valid image
        guard UIImage(data: data) != nil else {
            return nil
        }

        // Save to disk
        return try saveImageData(data, for: bookId)
    }

    /// Save image data to disk
    /// Returns the local file path
    func saveImageData(_ data: Data, for bookId: String) throws -> String? {
        guard let cacheDirectory = cacheDirectory else {
            return nil
        }

        let filename = "\(bookId).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        try data.write(to: fileURL)

        return filename // Return just the filename, not full path
    }

    /// Get the full file URL for a cached image
    func getImageURL(for filename: String) -> URL? {
        guard let cacheDirectory = cacheDirectory else {
            return nil
        }

        let fileURL = cacheDirectory.appendingPathComponent(filename)

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    /// Load cached image data
    func loadImage(for filename: String) async -> Data? {
        guard let fileURL = getImageURL(for: filename) else {
            return nil
        }

        return try? Data(contentsOf: fileURL)
    }

    /// Delete cached image
    func deleteImage(for filename: String) throws {
        guard let fileURL = getImageURL(for: filename) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    /// Clear all cached images
    func clearCache() throws {
        guard let cacheDirectory = cacheDirectory else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Get cache size in bytes
    func getCacheSize() async -> Int64 {
        guard let cacheDirectory = cacheDirectory else {
            return 0
        }

        var totalSize: Int64 = 0

        if let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for fileURL in contents {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }
}
