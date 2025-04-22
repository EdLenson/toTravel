import SwiftUI

struct CountryRow: View {
    let country: CountryAccess
    let countriesManager: CountriesManager
    let showDays: Bool
    let visa: Visa?
    let selectedPassport: Passport?
    @State private var flagImage: UIImage?
    @State private var isShowingDetail: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    private func loadFlagImage() {
        guard let url = countriesManager.getFlagURL(forCode: country.destination) else {
            return
        }
        
        let code = country.destination.lowercased()
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
        
        if fileManager.fileExists(atPath: fileURL.path),
           let image = UIImage(contentsOfFile: fileURL.path) {
            self.flagImage = image
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data),
                  let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            DispatchQueue.main.async {
                self.flagImage = image
                try? data.write(to: fileURL)
            }
        }.resume()
    }
    
    private var daysText: String {
        let requirement = country.requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        if let days = Int(requirement), days > 0 {
            return String(format: NSLocalizedString("до %d дн.", comment: "Days limit format"), days)
        } else {
            return NSLocalizedString("", comment: "Default days limit")
        }
    }
    
    private var subtitleText: String {
        if showDays {
            return daysText
        }
        
        guard let visa = visa else {
            return ""
        }
        
        let today = Date()
        if visa.endDate < today {
            return "" // Виза просрочена
        }
        
        if visa.startDate > today {
            return String(format: NSLocalizedString("виза действует с %@", comment: "Valid visa from date"), dateFormatter.string(from: visa.startDate))
        } else {
            return String(format: NSLocalizedString("действующая виза до %@", comment: "Valid visa until date"), dateFormatter.string(from: visa.endDate))
        }
    }
    
    var body: some View {
        Button(action: {
            isShowingDetail = true
        }) {
            HStack(alignment: .center, spacing: Theme.Tiles.spacing) {
                if let image = flagImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Color.gray
                        .frame(width: 32, height: 32)
                        .onAppear {
                            if flagImage == nil {
                                loadFlagImage()
                            }
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(countriesManager.getName(forCode: country.destination))
                        .font(Theme.Fonts.countryTitle)
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    if !subtitleText.isEmpty {
                        Text(subtitleText)
                            .font(Theme.Fonts.countrySubtitle)
                            .foregroundColor(Theme.Colors.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, Theme.Tiles.horizontalPadding)
            .padding(.vertical, Theme.Tiles.verticalPadding)
            .frame(maxWidth: .infinity, minHeight: Theme.Tiles.height, maxHeight: Theme.Tiles.height, alignment: .leading)
            .background(Theme.Colors.surface(for: colorScheme))
            .cornerRadius(Theme.Tiles.cornerRadius)
            .shadow(color: Theme.Tiles.shadowColor, radius: Theme.Tiles.shadowRadius, x: Theme.Tiles.shadowX, y: Theme.Tiles.shadowY)
        }
        .sheet(isPresented: $isShowingDetail) {
            if let countryDetail = countriesManager.countries.first(where: { $0.code == country.destination }) {
                CountryDetailView(
                    country: countryDetail,
                    selectedPassport: selectedPassport,
                    visa: visa // Передаём визу
                )
            } else {
                Text("Данные о стране не найдены")
            }
        }
    }
}
