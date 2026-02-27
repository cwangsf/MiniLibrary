//
//  RecentActivitySection.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "RecentActivitySection")

struct RecentActivitySection: View {
    @Environment(\.modelContext) private var modelContext
    let activities: [Activity]

    var body: some View {
        Section {
            VStack() {
                Text("Recent Activity")
                    .font(.headline)
                    .tint(.accent)
                    .padding(.vertical)
                
                if activities.isEmpty {
                    ContentUnavailableView(
                        "No Recent Activity",
                        systemImage: "clock",
                        description: Text("Activity will appear here as you use the library")
                    )
                } else {
                    ForEach(activities) { activity in
                        ActivityRowView(activity: activity)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    guard !activity.isDeleted else {
                                        logger.warning("Attempted to delete already deleted activity")
                                        return
                                    }
                                    modelContext.delete(activity)
                                    do {
                                        try modelContext.save()
                                        logger.info("Successfully deleted activity")
                                    } catch {
                                        logger.error("Failed to delete activity: \(error.localizedDescription)")
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                Spacer()
            }
        }
        .listRowSeparator(.hidden)
    }
}
