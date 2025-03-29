//
//  CustomTextField.swift
//  toTravel
//
//  Created by Ed on 3/21/25.
//

import SwiftUI

struct UnderlinedTextField: View {
    var title: String
    @Binding var text: String
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                // Название поля
                Text(title)
                    .foregroundColor(isEditing ? Color(hex: "#6464CB") : .gray)
                    .offset(y: isEditing || !text.isEmpty ? -25 : 0)
                    .scaleEffect(isEditing || !text.isEmpty ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !text.isEmpty)
                
                // Поле ввода
                TextField("", text: $text, onEditingChanged: { editing in
                    isEditing = editing
                })
            }
            .padding(.vertical, 12) // Увеличиваем отступы
            .overlay(
                Rectangle()
                    .frame(height: isEditing ? 2 : 1)
                    .foregroundColor(isEditing ? Color(hex: "#6464CB") : Color(hex: "#b9b9b9")),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .frame(height: 60) // Фиксированная высота поля
    }
}
