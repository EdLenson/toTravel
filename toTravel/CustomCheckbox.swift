import SwiftUI

struct CustomCheckbox: View {
    @Binding var isChecked: Bool
    let title: String
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isChecked ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.5))

                
                Text(title)
                    .foregroundColor(isChecked ? Theme.Colors.text : Theme.Colors.secondary)
                
                Spacer() // Добавляет пространство справа, растягивая HStack на всю ширину
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Растягиваем на всю ширину с выравниванием по левому краю
        }
        .buttonStyle(PlainButtonStyle())
    }
}
