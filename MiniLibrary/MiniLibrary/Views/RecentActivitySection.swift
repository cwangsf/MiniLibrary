//
//  RecentActivitySection.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct RecentActivitySection: View {
    @Environment(\.modelContext) private var modelContext
    let activities: [Activity]

    var body: some View {
        Section {
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
                                modelContext.delete(activity)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        } header: {
            Text("Recent Activity")
        }
        .listRowSeparator(.hidden)
    }
}
