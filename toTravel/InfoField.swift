//
//  InfoField.swift
//  toTravel
//
//  Created by Ed on 3/24/25.
//

import SwiftUI

struct InfoField: View {
    let label: String
    let value: String
    var valueColor: Color = .black
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) { // Отступ между названием и содержимым 2
            Text(label)
                .font(.system(size: 10, weight: .regular)) // Размер 10, regular
                .foregroundColor(Theme.Colors.secondary) // Цвет #9393A8
            Text(value)
                .font(.system(size: 16, weight: .regular)) // Размер 16, regular
                .foregroundColor(valueColor == .black ? Theme.Colors.text(for: colorScheme) : valueColor) // Основной цвет текста или указанный
        }
    }
}
