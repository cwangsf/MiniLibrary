//
//  ScannerCornerBrackets.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

/// Corner bracket overlay for barcode scanner frame
struct ScannerCornerBrackets: View {
    let color: Color
    let bracketLength: CGFloat
    let bracketThickness: CGFloat

    init(
        color: Color = .green,
        bracketLength: CGFloat = 40,
        bracketThickness: CGFloat = 4
    ) {
        self.color = color
        self.bracketLength = bracketLength
        self.bracketThickness = bracketThickness
    }

    var body: some View {
        ZStack {
            // Top-left corner
            CornerBracket(
                color: color,
                length: bracketLength,
                thickness: bracketThickness,
                corner: .topLeft
            )

            // Top-right corner
            CornerBracket(
                color: color,
                length: bracketLength,
                thickness: bracketThickness,
                corner: .topRight
            )

            // Bottom-left corner
            CornerBracket(
                color: color,
                length: bracketLength,
                thickness: bracketThickness,
                corner: .bottomLeft
            )

            // Bottom-right corner
            CornerBracket(
                color: color,
                length: bracketLength,
                thickness: bracketThickness,
                corner: .bottomRight
            )
        }
    }
}

/// Individual corner bracket component
private struct CornerBracket: View {
    let color: Color
    let length: CGFloat
    let thickness: CGFloat
    let corner: Corner

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        ZStack {
            // Horizontal bar
            VStack {
                if corner == .bottomLeft || corner == .bottomRight {
                    Spacer()
                }
                HStack {
                    if corner == .topRight || corner == .bottomRight {
                        Spacer()
                    }
                    Rectangle()
                        .fill(color)
                        .frame(width: length, height: thickness)
                    if corner == .topLeft || corner == .bottomLeft {
                        Spacer()
                    }
                }
                if corner == .topLeft || corner == .topRight {
                    Spacer()
                }
            }

            // Vertical bar
            VStack {
                if corner == .bottomLeft || corner == .bottomRight {
                    Spacer()
                }
                HStack {
                    if corner == .topRight || corner == .bottomRight {
                        Spacer()
                    }
                    Rectangle()
                        .fill(color)
                        .frame(width: thickness, height: length)
                    if corner == .topLeft || corner == .bottomLeft {
                        Spacer()
                    }
                }
                if corner == .topLeft || corner == .topRight {
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.green, lineWidth: 3)
            .frame(width: 280, height: 120)
            .overlay {
                ScannerCornerBrackets()
                    .padding(8)
            }
    }
}
