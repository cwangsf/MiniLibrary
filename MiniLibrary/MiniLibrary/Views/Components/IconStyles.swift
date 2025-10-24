//
//  IconStyles.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

// MARK: - Icon Style Modifiers

/// Standard icon style with color
struct IconStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
    }
}

/// Small icon style for inline use (e.g., in badges or compact rows)
struct SmallIconStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .foregroundStyle(color)
    }
}

/// Large decorative icon style
struct LargeIconStyle: ViewModifier {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat = 60) {
        self.color = color
        self.size = size
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
            .foregroundStyle(color)
    }
}

// MARK: - Semantic Icon Styles

/// Person icon style - blue colored
struct PersonIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.blue)
    }
}

/// Calendar icon style - blue colored
struct CalendarIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.blue)
    }
}

/// Success icon style - green colored
struct SuccessIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.green)
    }
}

/// Warning icon style - orange colored
struct WarningIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.orange)
    }
}

/// Error icon style - red colored
struct ErrorIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.red)
    }
}

// MARK: - View Extension
extension Image {
    /// Apply a colored icon style
    func iconStyle(color: Color) -> some View {
        modifier(IconStyle(color: color))
    }

    /// Small icon for inline use
    func smallIcon(color: Color) -> some View {
        modifier(SmallIconStyle(color: color))
    }

    /// Large decorative icon
    func largeIcon(color: Color, size: CGFloat = 60) -> some View {
        modifier(LargeIconStyle(color: color, size: size))
    }

    // Semantic icon styles

    /// Person icon - blue colored
    func personIcon() -> some View {
        modifier(PersonIconStyle())
    }

    /// Calendar icon - blue colored
    func calendarIcon() -> some View {
        modifier(CalendarIconStyle())
    }

    /// Success icon - green colored
    func successIcon() -> some View {
        modifier(SuccessIconStyle())
    }

    /// Warning icon - orange colored
    func warningIcon() -> some View {
        modifier(WarningIconStyle())
    }

    /// Error icon - red colored
    func errorIcon() -> some View {
        modifier(ErrorIconStyle())
    }
}
