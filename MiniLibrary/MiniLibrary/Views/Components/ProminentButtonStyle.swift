//
//  ProminentButtonStyle.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

// MARK: - Prominent Button Style
struct ProminentButtonStyle: ViewModifier {
    let color: Color
    let fullWidth: Bool

    init(color: Color, fullWidth: Bool = true) {
        self.color = color
        self.fullWidth = fullWidth
    }

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding()
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ViewModifier {
    let fullWidth: Bool

    init(fullWidth: Bool = true) {
        self.fullWidth = fullWidth
    }

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding()
            .background(.gray.opacity(0.2))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - View Extension
extension View {
    func prominentButton(color: Color, fullWidth: Bool = true) -> some View {
        modifier(ProminentButtonStyle(color: color, fullWidth: fullWidth))
    }

    func secondaryButton(fullWidth: Bool = true) -> some View {
        modifier(SecondaryButtonStyle(fullWidth: fullWidth))
    }
}
