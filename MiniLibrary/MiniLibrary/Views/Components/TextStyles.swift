//
//  TextStyles.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

// MARK: - Text Style Modifiers

/// Section title style - bold title2
struct SectionTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontWeight(.bold)
    }
}

/// Label style - caption with secondary color
struct LabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

/// Book title style - headline, centered
struct BookTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .multilineTextAlignment(.center)
    }
}

/// Book author style - subheadline with secondary color
struct BookAuthorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Value text style - headline for important values
struct ValueTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
    }
}

/// Badge style - small bold text with background
struct BadgeStyle: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color

    init(backgroundColor: Color = .red, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

// MARK: - View Extension
extension View {
    /// Section title style (title2, bold)
    func sectionTitle() -> some View {
        modifier(SectionTitleStyle())
    }

    /// Label style (caption, secondary)
    func labelStyle() -> some View {
        modifier(LabelStyle())
    }

    /// Book title style (headline, centered)
    func bookTitle() -> some View {
        modifier(BookTitleStyle())
    }

    /// Book author style (subheadline, secondary)
    func bookAuthor() -> some View {
        modifier(BookAuthorStyle())
    }

    /// Value text style (headline)
    func valueText() -> some View {
        modifier(ValueTextStyle())
    }

    /// Badge style with customizable colors
    func badge(backgroundColor: Color = .red, foregroundColor: Color = .white) -> some View {
        modifier(BadgeStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}
