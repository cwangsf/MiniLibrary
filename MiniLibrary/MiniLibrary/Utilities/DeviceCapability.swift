//
//  DeviceCapability.swift
//  MiniLibrary
//
//  Created by Claude on 2/28/26.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "DeviceCapability")

/// Utility for detecting device capabilities and conditionally enabling performance-intensive features
struct DeviceCapability {
    /// Shared singleton instance
    static let shared = DeviceCapability()
    
    /// Memory threshold in bytes (3GB)
    private static let memoryThresholdGB: UInt64 = 3
    private static let memoryThresholdBytes: UInt64 = memoryThresholdGB * 1024 * 1024 * 1024
    
    /// Device's physical memory in bytes
    let physicalMemory: UInt64
    
    /// Device's physical memory in GB (for logging)
    var physicalMemoryGB: Double {
        Double(physicalMemory) / (1024.0 * 1024.0 * 1024.0)
    }
    
    /// Whether device supports rich media features (images, animations, etc.)
    let supportsRichMedia: Bool
    
    /// Whether to display book cover images
    var shouldDisplayCoverImages: Bool {
        #if DEBUG
        // Allow override in debug builds via UserDefaults
        if UserDefaults.standard.object(forKey: "forceEnableCoverImages") != nil {
            return UserDefaults.standard.bool(forKey: "forceEnableCoverImages")
        }
        #endif
        return supportsRichMedia
    }
    
    /// Whether to perform background cover downloads
    var supportsBackgroundDownloads: Bool {
        #if DEBUG
        // Allow override in debug builds via UserDefaults
        if UserDefaults.standard.object(forKey: "forceEnableBackgroundDownloads") != nil {
            return UserDefaults.standard.bool(forKey: "forceEnableBackgroundDownloads")
        }
        #endif
        return supportsRichMedia
    }
    
    private init() {
        // Get device physical memory
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        self.physicalMemory = physicalMemory
        
        // Determine if device supports rich media based on memory
        let supportsRichMedia = physicalMemory >= Self.memoryThresholdBytes
        self.supportsRichMedia = supportsRichMedia
        
        // Calculate memory in GB for logging
        let physicalMemoryGB = Double(physicalMemory) / (1024.0 * 1024.0 * 1024.0)
        
        // Log device capability information
        logger.info("📱 Device Memory: \(String(format: "%.2f", physicalMemoryGB)) GB")
        logger.info("⚙️ Rich Media Support: \(supportsRichMedia ? "✅ Enabled" : "❌ Disabled") (Threshold: \(Self.memoryThresholdGB) GB)")
        logger.info("🖼️ Cover Images: \(supportsRichMedia ? "✅ Enabled" : "❌ Disabled")")
        logger.info("⬇️ Background Downloads: \(supportsRichMedia ? "✅ Enabled" : "❌ Disabled")")
    }
}
