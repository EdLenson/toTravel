//
//  FocusUtils.swift
//  toTravel
//
//  Created by Ed on 3/23/25.
//

import SwiftUI

extension View {
    func focusedField(isActive: Bool) -> some View {
        self.modifier(FocusedFieldModifier(isActive: isActive))
    }
}

struct FocusedFieldModifier: ViewModifier {
    let isActive: Bool
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isActive) { newValue in
                isFocused = newValue
            }
    }
}
