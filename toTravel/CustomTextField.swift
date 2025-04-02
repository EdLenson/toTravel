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
                Text(title)
                    .font(Theme.Fonts.countryTitle) // Размер 16 из Theme
                    .foregroundColor(isEditing ? Theme.Colors.primary : Theme.Colors.secondary)
                    .offset(y: isEditing || !text.isEmpty ? -25 : 0)
                    .scaleEffect(isEditing || !text.isEmpty ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isEditing || !text.isEmpty)
                
                TextField("", text: $text, onEditingChanged: { editing in
                    isEditing = editing
                })
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: isEditing ? 2 : 1)
                    .foregroundColor(isEditing ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.5)),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
    }
}
