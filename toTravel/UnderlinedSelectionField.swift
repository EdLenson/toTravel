//
//  UnderlinedSelectionField.swift
//  toTravel
//
//  Created by Ed on 3/22/25.
//

import SwiftUI

struct UnderlinedSelectionField: View {
    var title: String
    @Binding var selectedValue: String?
    var isActive: Bool // Заменили isFocused на isActive
    var action: () -> Void
    var onSelection: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? Color.blue : .gray)
                    .offset(y: isActive || selectedValue != nil ? -25 : 0)
                    .scaleEffect(isActive || selectedValue != nil ? 0.8 : 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.2), value: isActive || selectedValue != nil)
                
                if let selectedValue = selectedValue {
                    Text(selectedValue)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("")
                        .font(.system(size: 16))
                        .foregroundColor(.clear)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: isActive ? 2 : 1)
                    .foregroundColor(isActive ? Color.blue : Color.gray),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .background(Color.clear)
        .onChange(of: selectedValue) { newValue in
            print("UnderlinedSelectionField: selectedValue changed to \(newValue ?? "nil")")
            if newValue != nil {
                onSelection()
            }
        }
    }
}
