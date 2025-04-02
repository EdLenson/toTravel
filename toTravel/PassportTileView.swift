import SwiftUI

struct PassportTileView: View {
    let passport: Passport
    let dateFormatter: DateFormatter
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var countriesManager = CountriesManager.shared
    
    private var expiryText: String {
        let today = Calendar.current.startOfDay(for: Date())
        let expiry = Calendar.current.startOfDay(for: passport.expiryDate)
        
        if passport.expiryDate >= Date.distantFuture {
            return "Бессрочный"
        } else if today == expiry {
            return "Истекает сегодня"
        } else if expiry < today {
            return "Недействителен"
        } else {
            return "до \(dateFormatter.string(from: passport.expiryDate))"
        }
    }
    
    private var shouldHighlight: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let expiry = Calendar.current.startOfDay(for: passport.expiryDate)
        let components = Calendar.current.dateComponents([.month], from: today, to: expiry)
        
        if passport.expiryDate >= Date.distantFuture { return false }
        let monthsLeft = components.month ?? 0
        return monthsLeft < 6 || expiry <= today
    }
    
    private var passportIcon: String {
        passport.type == "Внутренний" ? "ic_passport" : "ic_biometric"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Image(passportIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(8)
            .background(Theme.Colors.background(for: colorScheme))
            .cornerRadius(8)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(passport.customName.isEmpty ? "Без названия" : passport.customName)
                    .font(Theme.Fonts.countryTitle)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                    .lineLimit(1)
                
                Text(expiryText)
                    .font(Theme.Fonts.countrySubtitle)
                    .foregroundColor(shouldHighlight ? Theme.Colors.expiring(for: colorScheme) : Theme.Colors.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(width: 160, height: 140, alignment: .leading)
        .background(Theme.Colors.surface(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Theme.Tiles.shadowColor, radius: Theme.Tiles.shadowRadius, x: Theme.Tiles.shadowX, y: Theme.Tiles.shadowY)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(
                    shouldHighlight ? Theme.Colors.expiring(for: colorScheme).opacity(0.25) : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    PassportTileView(
        passport: Passport(
            customName: "Тестовый паспорт",
            issuingCountry: "RU",
            expiryDate: Date().addingTimeInterval(60*60*24*30*5),
            type: "Заграничный"
        ),
        dateFormatter: {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter
        }()
    )
}
