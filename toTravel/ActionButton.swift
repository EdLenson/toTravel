//
//  ActionButton.swift
//  toTravel
//
//  Created by Ed on 3/23/25.
//

// ActionButton.swift
// toTravel
//
// Created by Ed on 3/23/25.
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(icon: String, title: String, color: Color = Theme.Colors.primary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(icon) // Используем кастомные иконки из Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Circle().fill(color))
                Text(title)
                    .padding(.top, 6)
                    .font(Theme.Fonts.buttonText)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
            }
        }
        .buttonStyle(ActionButtonStyle(color: color)) // Добавляем кастомный стиль для эффекта затемнения
    }
}

// Кастомный стиль кнопки для эффекта затемнения при нажатии
struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0) // Затемнение при нажатии
    }
}
