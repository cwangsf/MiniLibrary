//
//  ExportImportRows.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

// MARK: - Export Catalog Row
struct ExportCatalogRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Export Wishlist Row
struct ExportWishlistRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Import Catalog Row
struct ImportCatalogRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.blue)
                    Text("Import Catalog from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: Title, Author, ISBN")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: ISBN, Title.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}

// MARK: - Import Wishlist Row
struct ImportWishlistRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.green)
                    Text("Import Wishlist from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: Title, Author, ISBN")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: Title. Author and ISBN are optional but improve search accuracy.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}

// MARK: - Export Students Row
struct ExportStudentsRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Students to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Students to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Students to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Import Students Row
struct ImportStudentsRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.orange)
                    Text("Import Students from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: First Name, Last Name, Class")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: First Name, Last Name. Class is optional.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}

// MARK: - Export Checkouts Row
struct ExportCheckoutsRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Checkout Records to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Checkout Records to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Checkout Records to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Import Checkout Records Row
struct ImportCheckoutRecordsRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.purple)
                    Text("Import Checkout Records from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: Book Title, Student Name, Checkout Date, Due Date")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: Book Title, Student Name. Dates are optional.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}
