import SwiftUI

// MARK: - View Extension
extension View {
    func focusedField(isActive: Bool) -> some View {
        self.modifier(FocusedFieldModifier(isActive: isActive))
    }
}

// MARK: - FocusedFieldModifier
struct FocusedFieldModifier: ViewModifier {
    let isActive: Bool
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isActive) { _, newValue in // Обновлено для iOS 17+
                isFocused = newValue
            }
    }
}
