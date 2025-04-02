import SwiftUI
import SwiftData

struct CountryRow: View {
    let country: CountryAccess
    let countriesManager: CountriesManager
    let showDays: Bool
    @State private var flagImage: UIImage? = nil
    @State private var flagLoadError: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    private func flagURL(for countryCode: String) -> URL? {
        let code = countryCode.lowercased()
        let urlString = "https://flagcdn.com/w320/\(code).png"
        return URL(string: urlString)
    }
    
    private func loadFlagImage() {
        guard let url = flagURL(for: country.destination) else {
            flagLoadError = true
            return
        }
        
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(country.destination.lowercased()).png")
        
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
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.flagLoadError = true
                }
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
            return "до \(days) дн."
        } else {
            return "до 365 дней*"
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Theme.Tiles.spacing) {
            if flagImage == nil && !flagLoadError {
                Color.gray
                    .frame(width: 32, height: 32)
            } else if flagLoadError {
                Color.gray
                    .frame(width: 32, height: 32)
            } else if let image = flagImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(countriesManager.getName(forCode: country.destination))
                    .font(Theme.Fonts.countryTitle)
                    .foregroundColor(Theme.Colors.text(for: colorScheme))
                
                if showDays {
                    Text(daysText)
                        .font(Theme.Fonts.countrySubtitle)
                        .foregroundColor(Theme.Colors.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Tiles.horizontalPadding)
        .padding(.vertical, Theme.Tiles.verticalPadding)
        .frame(maxWidth: .infinity,
               minHeight: Theme.Tiles.height,
               maxHeight: Theme.Tiles.height,
               alignment: .leading)
        .background(Theme.Colors.surface(for: colorScheme))
        .cornerRadius(Theme.Tiles.cornerRadius)
        .shadow(color: Theme.Tiles.shadowColor,
                radius: Theme.Tiles.shadowRadius,
                x: Theme.Tiles.shadowX,
                y: Theme.Tiles.shadowY)
        .onAppear {
            loadFlagImage()
        }
        .onChange(of: country.destination) { _ in
            flagImage = nil
            flagLoadError = false
            loadFlagImage()
        }
    }
}
