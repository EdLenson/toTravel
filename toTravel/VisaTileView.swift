import SwiftUI

struct VisaTileView: View {
    let visa: Visa
    let dateFormatter: DateFormatter
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var countriesManager = CountriesManager.shared
    @State private var flagImage: UIImage? = nil
    @State private var flagLoadError: Bool = false
    
    private var expiryText: String {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: visa.endDate)
        
        if today == end {
            return "Истекает сегодня"
        } else if end < today {
            return "Недействительна"
        } else {
            return "до \(dateFormatter.string(from: visa.endDate))"
        }
    }
    
    private var shouldHighlight: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: visa.endDate)
        let components = Calendar.current.dateComponents([.month], from: today, to: end)
        
        let monthsLeft = components.month ?? 0
        return monthsLeft < 3 || end <= today
    }
    
    private func loadFlagImage() {
        guard let url = countriesManager.getFlagURL(forCode: visa.issuingCountry) else {
            flagLoadError = true
            print("URL флага не найден для кода: \(visa.issuingCountry)")
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(visa.issuingCountry.lowercased()).png")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                DispatchQueue.main.async {
                    self.flagImage = image
                }
                return
            }
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.flagLoadError = true
                }
                print("Ошибка загрузки флага для \(visa.issuingCountry): \(error.localizedDescription)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.flagLoadError = true
                }
                print("Данные флага для \(visa.issuingCountry) невалидны")
                return
            }
            DispatchQueue.main.async {
                self.flagImage = image
                try? data.write(to: fileURL)
            }
        }.resume()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                if flagLoadError || flagImage == nil {
                    Color.gray
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                } else if let image = flagImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                }
            }
            .padding(8)
            .background(Theme.Colors.background(for: colorScheme))
            .cornerRadius(8)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(visa.customName.isEmpty ? "Без названия" : visa.customName)
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
        .onAppear {
            loadFlagImage()
        }
        .onChange(of: visa.issuingCountry) { _ in
            flagImage = nil
            flagLoadError = false
            loadFlagImage()
        }
    }
}

#Preview {
    VisaTileView(
        visa: Visa(
            customName: "Test Visa",
            passport: nil,
            issuingCountry: "RU",
            entriesCount: 1,
            issueDate: Date(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(60*60*24*90),
            validityPeriod: 30
        ),
        dateFormatter: {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter
        }()
    )
}
