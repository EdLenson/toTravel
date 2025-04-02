// UnderlinedSelectionField.swift
// toTravel
//
// Created by Ed on 3/22/25.
//

import SwiftUI

struct UnderlinedSelectionField: View {
    var title: String
    @Binding var selectedValue: String?
    var isActive: Bool
    var action: () -> Void
    var onSelection: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title)
                    .font(Theme.Fonts.countryTitle) // Размер 16 из Theme
                    .foregroundColor(isActive ? Theme.Colors.primary : Theme.Colors.secondary)
                    .offset(y: isActive || selectedValue != nil ? -25 : 0)
                    .scaleEffect(isActive || selectedValue != nil ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isActive || selectedValue != nil)
                
                if let selectedValue = selectedValue {
                    Text(selectedValue)
                        .font(Theme.Fonts.countryTitle)
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("")
                        .font(Theme.Fonts.countryTitle)
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: isActive ? 2 : 1)
                    .foregroundColor(isActive ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.5)),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        //.padding(.horizontal, Theme.Tiles.verticalPadding) // Отступ от краев 8
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        //.background(Theme.Colors.background(for: colorScheme)) // Прозрачный фон заменен на background из Theme
        .onChange(of: selectedValue) { newValue in
            print("UnderlinedSelectionField: selectedValue changed to \(newValue ?? "nil")")
            if newValue != nil {
                onSelection()
            }
        }
    }
}
