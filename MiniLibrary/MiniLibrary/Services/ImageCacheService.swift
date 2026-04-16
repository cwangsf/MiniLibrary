//
//  ImageCacheService.swift
//  MiniLibrary
//
//  Created by Claude on 10/16/25.
//

import Foundation
import UIKit
import os

/// Service for caching book cover images to disk
actor ImageCacheService {
    static let shared = ImageCacheService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "ImageCacheService")
    private nonisolated(unsafe) let fileManager = FileManager.default
    private let cacheDirectory: URL?       // Caches/ — evictable, for API-downloaded covers
    private let userCoversDirectory: URL?  // Documents/ — persistent, for user-picked covers

    private init() {
        // API cover cache — evictable
        if let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let dir = cachesDirectory.appendingPathComponent("BookCovers", isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            self.cacheDirectory = fileManager.fileExists(atPath: dir.path) ? dir : nil
        } else {
            self.cacheDirectory = nil
        }

        // User cover store — persistent, never evicted by the OS
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dir = documentsDirectory.appendingPathComponent("UserBookCovers", isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            self.userCoversDirectory = fileManager.fileExists(atPath: dir.path) ? dir : nil
        } else {
            self.userCoversDirectory = nil
        }
    }

    // MARK: - Public Methods

    /// Download and cache an image from URL
    /// Returns the local file path if successful
    func cacheImage(from urlString: String, for bookId: String) async throws -> String? {
        // Ensure we have a valid URL
        guard let url = URL(string: urlString) else {
            return nil
        }

        // Download the image
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP response status
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                // Not found or error - don't cache
                return nil
            }
        }
        
        // Validate that the data is actually a valid image
        guard data.count > 100 else { // Image files should be larger than 100 bytes
            return nil
        }
        
        // Try to create UIImage to validate it's a real image
        guard UIImage(data: data) != nil else {
            return nil
        }

        // Save to disk
        return try saveImageData(data, for: bookId)
    }

    /// Save API-downloaded image data to the evictable cache directory.
    /// Returns the filename on success.
    func saveImageData(_ data: Data, for bookId: String) throws -> String? {
        guard let cacheDirectory = cacheDirectory else { return nil }
        let filename = "\(bookId).jpg"
        try data.write(to: cacheDirectory.appendingPathComponent(filename))
        return filename
    }

    /// Save a user-picked cover image to the persistent Documents directory.
    /// Returns the filename (prefixed with "user_") on success.
    func saveUserImageData(_ data: Data, for bookId: String) throws -> String? {
        guard let userCoversDirectory = userCoversDirectory else { return nil }
        let filename = "user_\(bookId).jpg"
        try data.write(to: userCoversDirectory.appendingPathComponent(filename))
        return filename
    }

    /// Get the full file URL for a cached image.
    /// Checks the user covers directory first (persistent), then the API cache.
    func getImageURL(for filename: String) -> URL? {
        if filename.hasPrefix("user_"), let dir = userCoversDirectory {
            let url = dir.appendingPathComponent(filename)
            return fileManager.fileExists(atPath: url.path) ? url : nil
        }
        if let dir = cacheDirectory {
            let url = dir.appendingPathComponent(filename)
            return fileManager.fileExists(atPath: url.path) ? url : nil
        }
        return nil
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
