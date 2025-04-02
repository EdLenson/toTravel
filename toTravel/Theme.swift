import SwiftUI

struct Theme {
    struct Colors {
        static let primary = Color(hex: "7878F2")
        static let secondary = Color(hex: "9393A8")
        static let background = Color(hex: "F7F7F8")
        static let surface = Color(hex: "FFFFFF")
        static let text = Color(hex: "1C1C1C")
        static let textInverse = Color(hex: "FFFFFF")
        static let alternateBackground = Color(hex: "EDEDF0")
        static let expiring = Color(hex: "EA5A57")
        
        struct Dark {
            static let primary = Color(hex: "8E8EF6")
            static let secondary = Color(hex: "9B9BB4")
            static let background = Color(hex: "1C1C1E")
            static let surface = Color(hex: "313036")
            static let text = Color(hex: "F6F6F8")
            static let textInverse = Color(hex: "FFFFFF")
            static let alternateBackground = Color(hex: "45444B")
            static let expiring = Color(hex: "D45754")
        }
        
        static func text(for scheme: ColorScheme) -> Color {
            scheme == .dark ? Dark.text : text
        }
        
        static func background(for scheme: ColorScheme) -> Color {
            scheme == .dark ? Dark.background : background
        }
        
        static func surface(for scheme: ColorScheme) -> Color {
            scheme == .dark ? Dark.surface : surface
        }
        
        static func alternateBackground(for scheme: ColorScheme) -> Color {
            scheme == .dark ? Dark.alternateBackground : alternateBackground
        }
        
        static func expiring(for scheme: ColorScheme) -> Color {
            scheme == .dark ? Dark.expiring : expiring
        }
    }
    
    struct Fonts {
        static let button = Font.system(size: 16, weight: .semibold)
        static let buttonText = Font.system(size: 13)
        static let countryTitle = Font.system(size: 16)
        static let countrySubtitle = Font.system(size: 13)
        static let tab = Font.system(size: 12, weight: .medium)
        static let header = Font.system(size: 24, weight: .semibold) // Новый стиль заголовка
    }
    
    struct Tiles {
        static let cornerRadius: CGFloat = 16
        static let height: CGFloat = 68
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 16
        static let spacing: CGFloat = 16
        static let shadowColor = Color(red: 0.11, green: 0.11, blue: 0.18).opacity(0.05)
        static let shadowRadius: CGFloat = 9
        static let shadowX: CGFloat = 0
        static let shadowY: CGFloat = 5
        static let tabHorizontalPadding: CGFloat = 12
        static let tabVerticalPadding: CGFloat = 6
        static let tabCornerRadius: CGFloat = 24
        static let tabSpacing: CGFloat = 8
        static let listSpacing: CGFloat = 8
        static let listEdgePadding: CGFloat = 8
        static let passportCornerRadius: CGFloat = 16
    }
}
