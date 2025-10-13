//
//  SectionIndexTitles.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/13/25.
//

import SwiftUI

struct SectionIndexTitles: View {
    let titles: [String]
    let onTap: (String) -> Void

    @State private var selectedLetter: String?
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 2) {
            ForEach(titles, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selectedLetter == letter ? .white : .blue)
                    .frame(width: 20, height: 16)
                    .background(
                        Circle()
                            .fill(selectedLetter == letter ? Color.blue : Color.clear)
                            .frame(width: 18, height: 18)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleLetterSelection(letter)
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(at: value.location)
                }
                .onEnded { _ in
                    selectedLetter = nil
                }
        )
    }

    private func handleLetterSelection(_ letter: String) {
        selectedLetter = letter
        hapticFeedback.impactOccurred()
        onTap(letter)

        // Clear selection after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedLetter = nil
        }
    }

    private func handleDrag(at location: CGPoint) {
        // Calculate which letter is being dragged over
        let itemHeight: CGFloat = 18 // height + spacing
        let index = Int(location.y / itemHeight)

        if index >= 0 && index < titles.count {
            let letter = titles[index]
            if selectedLetter != letter {
                selectedLetter = letter
                hapticFeedback.impactOccurred()
                onTap(letter)
            }
        }
    }
}
