//
//  MainTabView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

// MARK: - Tab Enum
enum AppTab: Hashable, CaseIterable {
    case home
    case catalog
    case add

    var label: String {
        switch self {
        case .home:
            return String(localized: "Home")
        case .catalog:
            return String(localized: "Catalog")
        case .add:
            return String(localized: "Add")
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .catalog:
            return "books.vertical.fill"
        case .add:
            return "plus.circle.fill"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            HomeView()
        case .catalog:
            CatalogView()
        case .add:
            AddView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tab.view
                    .tabItem {
                        Label(tab.label, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
    }
}

#Preview {
    MainTabView()
}
