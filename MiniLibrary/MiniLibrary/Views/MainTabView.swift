//
//  MainTabView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CatalogView()
                .tabItem {
                    Label("Catalog", systemImage: "books.vertical.fill")
                }

            AddView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
