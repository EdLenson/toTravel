//
//  ActionButton.swift
//  toTravel
//
//  Created by Ed on 3/23/25.
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color = .accentColor, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}
