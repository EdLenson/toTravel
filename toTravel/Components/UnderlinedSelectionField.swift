import SwiftUI

// MARK: - UnderlinedSelectionField
struct UnderlinedSelectionField: View {
    var title: String
    @Binding var selectedValue: String?
    var isActive: Bool
    var action: () -> Void
    var onSelection: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                Text(title)
                    .font(Theme.Fonts.countryTitle)
                    .foregroundColor(isActive ? Theme.Colors.primary(for: colorScheme) : Theme.Colors.secondary(for: colorScheme))
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
                    .foregroundColor(isActive ? Theme.Colors.primary(for: colorScheme) : Theme.Colors.secondary(for: colorScheme).opacity(0.5)),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onChange(of: selectedValue) { _, newValue in // Обновлено для iOS 17+
            if newValue != nil {
                onSelection()
            }
        }
    }
}
