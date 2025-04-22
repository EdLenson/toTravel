import SwiftUI
import UIKit

struct CountryDetailView: View {
    // MARK: - Properties
    
    let country: CountriesManager.Country
    let selectedPassport: Passport?
    let visa: Visa?
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var countryImage: UIImage?
    @State private var flagImage: UIImage?
    @State private var isLoadingImage = true
    @State private var weather: WeatherData?
    @State private var waveOffset: CGFloat = -1.0
    @State private var wikipediaSummary: String?
    
    private let unsplashAccessKey = "DpqShkZaVZlp4N5hq3OA-HQ4b_JWqg2Tu5emqdYGhxA"
    private let weatherAPIKey = "e3083d4221be462882d72116251004"
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Displays country photo, flag, name, and weather
                ZStack(alignment: .bottom) {
                    if isLoadingImage || countryImage == nil {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Theme.Colors.alternateBackground(for: colorScheme).opacity(0.3),
                                        Theme.Colors.alternateBackground(for: colorScheme).opacity(0.7),
                                        Theme.Colors.alternateBackground(for: colorScheme).opacity(0.3)
                                    ]),
                                    startPoint: .init(x: waveOffset, y: 0.5),
                                    endPoint: .init(x: waveOffset + 1.0, y: 0.5)
                                )
                            )
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                            .cornerRadius(8)
                            .onAppear {
                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    waveOffset = 1.0
                                }
                            }
                            .onDisappear {
                                waveOffset = -1.0
                            }
                    } else {
                        GeometryReader { geometry in
                            Image(uiImage: countryImage!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: 200)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "1C1C1E").opacity(0.7),
                                            Color(hex: "1C1C1E").opacity(0.0)
                                        ]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                    .cornerRadius(8)
                                )
                        }
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                    }
                    
                    VStack(spacing: 0) {
                        if let flagImage {
                            Image(uiImage: flagImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                        } else {
                            Theme.Colors.secondary(for: colorScheme)
                                .frame(width: 20, height: 15)
                        }
                        
                        Text(country.name)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(countryImage == nil ? Theme.Colors.text(for: colorScheme) : Theme.Colors.textInverse)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        
                        Group {
                            if let weather, let capital = country.capital.first {
                                let emoji = weatherEmoji(weather.condition)
                                Text("\(localizedCapital(capital)) \(emoji.isEmpty ? "" : emoji + " ")\(weather.temperature > 0 ? "" : "")\(Int(weather.temperature))°C")
                                    .font(.system(size: 16))
                                    .foregroundColor(countryImage == nil ? Theme.Colors.text(for: colorScheme) : Theme.Colors.textInverse)
                                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                            } else {
                                Text("")
                                    .font(.system(size: 16))
                                    .foregroundColor(.clear)
                            }
                        }
                        .frame(height: 24)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Displays country info chips in a horizontal scrollable row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(createTags()) { tag in
                            if let currencyCode = tag.currencyCode {
                                Button(action: {
                                    NotificationCenter.default.post(name: .didTapCurrencyChip, object: currencyCode)
                                }) {
                                    chipContent(tag: tag)
                                }
                                .buttonStyle(.plain)
                            } else if let capitalName = tag.capitalName {
                                Button(action: {
                                    NotificationCenter.default.post(name: .didTapCapitalChip, object: capitalName)
                                }) {
                                    chipContent(tag: tag)
                                }
                                .buttonStyle(.plain)
                            } else {
                                chipContent(tag: tag)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                // Displays Wikipedia summary and link
                VStack(alignment: .leading, spacing: 0) {
                    Text(NSLocalizedString("О стране", comment: ""))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    if let summary = wikipediaSummary {
                        Text(summary)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                            .padding(.top, 8)
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                        
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("Подробнее на", comment: ""))
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondary(for: colorScheme))
                            
                            Link(NSLocalizedString("Википедия", comment: ""), destination: wikipediaURL)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.primary(for: colorScheme))
                        }
                        .padding(.top, 12)
                    } else {
                        Text(NSLocalizedString("Загрузка...", comment: ""))
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.5))
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Displays visa requirements and details link
                VStack(alignment: .leading, spacing: 0) {
                    Text(NSLocalizedString("О визе", comment: ""))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                    
                    Text(visaRequirementText)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text(for: colorScheme))
                        .padding(.top, 16)
                    
                    if let visa, visa.endDate >= Date() {
                        Text(visa.startDate > Date() ?
                             String(format: NSLocalizedString("Ваша виза действует с %@", comment: "Your Visa valid from date"), dateFormatter.string(from: visa.startDate)) :
                             String(format: NSLocalizedString("У вас есть действующая виза до %@", comment: "Valid visa until date"), dateFormatter.string(from: visa.endDate)))
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.text(for: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                            .background(Theme.Colors.positiveGreen(for: colorScheme).opacity(0.13))
                            .cornerRadius(8)
                            .padding(.top, 8)
                    }
                    
                    Link(NSLocalizedString("Подробная информация", comment: ""), destination: visaSearchURL)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.alternateBackground(for: colorScheme))
                        .foregroundColor(Theme.Colors.primary(for: colorScheme))
                        .cornerRadius(8)
                        .padding(.top, 16)
                        .buttonStyle(.plain)
                }
                .padding(16)
                .background(Theme.Colors.surface(for: colorScheme))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
        }
        .id(country.code)
        .background(Theme.Colors.background(for: colorScheme))
        .onReceive(NotificationCenter.default.publisher(for: .didTapCurrencyChip)) { notification in
            if let currencyCode = notification.object as? String,
               let url = currencyConversionURL(for: currencyCode) {
                UIApplication.shared.open(url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapCapitalChip)) { notification in
            if let capitalName = notification.object as? String,
               let url = capitalMapURL(for: capitalName) {
                UIApplication.shared.open(url)
            }
        }
        .onAppear {
            countryImage = nil
            flagImage = nil
            isLoadingImage = true
            weather = nil
            waveOffset = -1.0
        }
        .task {
            loadFlagFromCache()
            await loadCountryImage()
            await loadWeatherData()
            if wikipediaSummary == nil {
                await loadWikipediaSummary()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// URL for the country's Wikipedia page
    private var wikipediaURL: URL {
        let language = Locale.current.language.languageCode?.identifier == "ru" ? "ru" : "en"
        var countryName = language == "ru" ? country.nameRu : country.nameEn
        
        let titleExceptions = [
            "Северная Корея": "Корейская Народно-Демократическая Республика",
            "Южная Корея": "Республика Корея",
            "Туркмения": "Туркменистан",
            "Bahamas": "The Bahamas"
        ]
        
        if language == "ru", let exception = titleExceptions[countryName] {
            countryName = exception
        }
        
        let encodedTitle = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://\(language).wikipedia.org/wiki/\(encodedTitle)")!
    }
    
    /// Visa requirement text based on selected passport
    private var visaRequirementText: String {
        guard let passportCode = selectedPassport?.issuingCountry else {
            return NSLocalizedString("Выберите паспорт для визовой информации", comment: "")
        }
        
        guard let countryAccessList = CountriesManager.shared.countryAccessData[passportCode],
              let access = countryAccessList.first(where: { $0.destination == country.code }) else {
            return NSLocalizedString("Информация о визе недоступна", comment: "")
        }
        
        switch access.requirement.lowercased() {
        case "visafree", "visa free", "-1", "0", "30", "60", "90", "180", "360":
            return NSLocalizedString("Для вашего паспорта не требуется виза", comment: "")
        case "visaonarrival", "visa on arrival":
            return NSLocalizedString("По прибытии в страну вы получите визу", comment: "")
        case "evisa", "e-visa", "eta":
            return NSLocalizedString("Для поездки нужна электронная виза", comment: "")
        case "visarequired", "visa required":
            return NSLocalizedString("Для поездки нужна виза", comment: "")
        case "noadmission", "no admission":
            return NSLocalizedString("Вероятно, въезд в страну запрещён или визовый режим для вашего паспорта неизвестен", comment: "")
        default:
            return NSLocalizedString("Информация о визе недоступна", comment: "")
        }
    }
    
    /// URL for visa information search
    private var visaSearchURL: URL {
        let isRussian = Locale.current.language.languageCode?.identifier == "ru"
        let query = isRussian ? NSLocalizedString("Виза в", comment: "") + " \(country.nameRu)" : "Visa to \(country.nameEn)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return URL(string: "https://www.google.com/search?q=\(encodedQuery)")!
    }
    
    // MARK: - Helper Methods
    
    /// Creates info chips for country details
    private func createTags() -> [TagViewItem] {
        [
            TagViewItem(
                title: localizedCapitals(country.capital).joined(separator: ", "),
                icon: "ic_flag",
                capitalName: country.capital.first
            ),
            TagViewItem(title: getCapitalTime(), icon: "ic_clock"),
            TagViewItem(title: localizedRegion(country.region), icon: "ic_region"),
            TagViewItem(
                title: localizedLanguages(country.languages.values).joined(separator: ", "),
                icon: "ic_language"
            ),
            TagViewItem(title: localizedDrivingSide(country.drivingSide), icon: "ic_carSide"),
            TagViewItem(
                title: localizedCurrencies(country.currencies).first ?? NSLocalizedString("N/A", comment: ""),
                icon: "ic_currency",
                currencyCode: country.currencies.first?.code
            )
        ]
    }
    
    /// Renders content for a single chip
    private func chipContent(tag: TagViewItem) -> some View {
        HStack(spacing: 8) {
            Image(tag.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(Theme.Colors.primary(for: colorScheme))
            Text(tag.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tag.currencyCode != nil || tag.capitalName != nil ? Theme.Colors.primary(for: colorScheme) : Theme.Colors.text(for: colorScheme))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.Colors.surface(for: colorScheme))
        .cornerRadius(8)
    }
    
    private func localizedCapital(_ capital: String) -> String {
        NSLocalizedString(capital, comment: "Capital name")
    }
    
    private func localizedCapitals(_ capitals: [String]) -> [String] {
        capitals.map(localizedCapital)
    }
    
    private func localizedRegion(_ region: String) -> String {
        NSLocalizedString(region, comment: "Region name")
    }
    
    private func localizedLanguages(_ languages: some Collection<String>) -> [String] {
        Array(languages.prefix(3)).map { NSLocalizedString($0, comment: "Language name") }
    }
    
    private func localizedDrivingSide(_ side: String) -> String {
        NSLocalizedString(side, comment: "Driving side")
    }
    
    private func localizedCurrencies(_ currencies: [CountriesManager.Country.Currency]) -> [String] {
        currencies.map { NSLocalizedString($0.name, comment: "Currency name") }
    }
    
    /// Calculates current time in the capital city
    private func getCapitalTime() -> String {
        let timeZones: [String: String]
        do {
            guard let url = Bundle.main.url(forResource: "capital_timezones", withExtension: "json") else {
                return NSLocalizedString("N/A", comment: "")
            }
            let data = try Data(contentsOf: url)
            timeZones = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            return NSLocalizedString("N/A", comment: "")
        }
        
        guard let timeZoneId = timeZones[country.code] else {
            return NSLocalizedString("N/A", comment: "")
        }
        
        guard !timeZoneId.isEmpty else {
            return NSLocalizedString("N/A", comment: "")
        }
        
        let cleanedTimeZoneId = timeZoneId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let timeZone = TimeZone(identifier: cleanedTimeZoneId) else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.timeZone = .current
            return formatter.string(from: Date()) // Fallback: локальное время
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        let time = formatter.string(from: Date())
        
        let localSeconds = TimeZone.current.secondsFromGMT()
        let countrySeconds = timeZone.secondsFromGMT()
        let offsetHours = (countrySeconds - localSeconds) / 3600
        
        if offsetHours == 0 {
            return time
        }
        
        let offsetString = String(format: "%+d%@", offsetHours, NSLocalizedString("ч", comment: ""))
        return "\(time) (\(offsetString))"
    }
    
    private func getUserCurrencyCode() -> String {
        guard let passportCountryCode = selectedPassport?.issuingCountry,
              let passportCountry = CountriesManager.shared.countries.first(where: { $0.code == passportCountryCode }),
              let currencyCode = passportCountry.currencies.first?.code else {
            return "USD"
        }
        return currencyCode
    }
    
    private func currencyConversionURL(for currencyCode: String) -> URL? {
        let userCurrency = getUserCurrencyCode()
        let query = "\(userCurrency)+to+\(currencyCode)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: "https://www.google.com/search?q=\(encodedQuery ?? "")")
    }
    
    private func capitalMapURL(for capitalName: String) -> URL? {
        let query = "q=\(capitalName)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: "https://maps.apple.com/?\(encodedQuery ?? "")")
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads flag image from cache or triggers network request
    private func loadFlagFromCache() {
        let code = country.code.lowercased()
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
        
        if fileManager.fileExists(atPath: fileURL.path),
           let image = UIImage(contentsOfFile: fileURL.path) {
            flagImage = image
        } else {
            Task {
                await loadFlagImage()
            }
        }
    }
    
    /// Fetches flag image from network and caches it
    private func loadFlagImage() async {
        guard let url = URL(string: country.flagURL) else { return }
        
        let code = country.code.lowercased()
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code).png")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return
            }
            await MainActor.run {
                flagImage = image
            }
            try? data.write(to: fileURL)
        } catch {
            print(NSLocalizedString("Ошибка загрузки флага", comment: "") + ": \(error)")
        }
    }
    
    /// Loads country image from cache or Unsplash using capital and country name
    private func loadCountryImage() async {
        let code = country.code.lowercased()
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = cachesDirectory.appendingPathComponent("\(code)_photo.png")
        
        if fileManager.fileExists(atPath: fileURL.path),
           let image = UIImage(contentsOfFile: fileURL.path) {
            await MainActor.run {
                countryImage = image
                isLoadingImage = false
            }
            return
        }
        
        let isRussian = Locale.current.language.languageCode?.identifier == "ru"
        let countryName = isRussian ? country.nameRu : country.nameEn
        let capital = country.capital.first ?? countryName
        let query = capital.lowercased() == countryName.lowercased() ? capital : "\(capital) \(countryName)"
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            await MainActor.run {
                isLoadingImage = false
            }
            return
        }
        
        let urlString = "https://api.unsplash.com/search/photos?query=\(encodedQuery)&per_page=1&order_by=relevant&orientation=landscape&client_id=\(unsplashAccessKey)"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                isLoadingImage = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    isLoadingImage = false
                }
                return
            }
            let responseData = try JSONDecoder().decode(UnsplashPhotoResponse.self, from: data)
            
            guard let photoURL = responseData.results.first?.urls.regular,
                  let imageURL = URL(string: "\(photoURL)&w=1080") else {
                await MainActor.run {
                    isLoadingImage = false
                }
                return
            }
            
            let (imageData, imageResponse) = try await URLSession.shared.data(from: imageURL)
            guard let imageHttpResponse = imageResponse as? HTTPURLResponse, imageHttpResponse.statusCode == 200,
                  let image = UIImage(data: imageData) else {
                await MainActor.run {
                    isLoadingImage = false
                }
                return
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    countryImage = image
                    isLoadingImage = false
                }
            }
            try? imageData.write(to: fileURL)
        } catch {
            print(NSLocalizedString("Ошибка загрузки фото с Unsplash", comment: "") + ": \(error)")
            await MainActor.run {
                isLoadingImage = false
            }
        }
    }
    
    /// Fetches current weather data for the capital city
    private func loadWeatherData() async {
        guard let coordinates = country.capitalCoordinates else { return }
        let urlString = "https://api.weatherapi.com/v1/current.json?key=\(weatherAPIKey)&q=\(coordinates.latitude),\(coordinates.longitude)"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            let responseData = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
            await MainActor.run {
                weather = responseData.current
            }
        } catch {
            print(NSLocalizedString("Ошибка загрузки данных о погоде", comment: "") + ": \(error)")
        }
    }
    
    /// Fetches and processes Wikipedia summary for the country
    private func loadWikipediaSummary() async {
        let language = Locale.current.language.languageCode?.identifier == "ru" ? "ru" : "en"
        var countryName = language == "ru" ? country.nameRu : country.nameEn
        
        let titleExceptions = [
            "Северная Корея": "Корейская Народно-Демократическая Республика",
            "Южная Корея": "Республика Корея",
            "Туркмения": "Туркменистан",
            "Bahamas": "The Bahamas"
        ]
        
        if language == "ru", let exception = titleExceptions[countryName] {
            countryName = exception
        }
        
        guard let encodedTitle = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            await MainActor.run {
                wikipediaSummary = NSLocalizedString("Информация недоступна", comment: "")
            }
            return
        }
        
        let urlString = "https://\(language).wikipedia.org/w/api.php?action=query&prop=extracts&exintro&explaintext&format=json&titles=\(encodedTitle)"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                wikipediaSummary = NSLocalizedString("Информация недоступна", comment: "")
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    wikipediaSummary = NSLocalizedString("Информация недоступна", comment: "")
                }
                return
            }
            let responseData = try JSONDecoder().decode(WikipediaResponse.self, from: data)
            
            guard let page = responseData.query.pages.values.first,
                  let extract = page.extract else {
                await MainActor.run {
                    wikipediaSummary = NSLocalizedString("Информация недоступна", comment: "")
                }
                return
            }
            
            // Clean text by removing unwanted elements
            var cleanedText = extract
            cleanedText = cleanedText.replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: ":\\s*,", with: "", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "[—–]\\s*-", with: "—", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "\\s*\\.\\s*", with: ". ", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "\\s+,\\s*", with: ",", options: .regularExpression)
            cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Split text into sentences
            var sentences: [String] = []
            var currentSentence = ""
            var i = 0
            while i < cleanedText.count {
                let index = cleanedText.index(cleanedText.startIndex, offsetBy: i)
                currentSentence.append(cleanedText[index])
                
                if cleanedText[index] == "." {
                    var isSentenceEnd = false
                    if i == cleanedText.count - 1 {
                        isSentenceEnd = true
                    } else if i + 1 < cleanedText.count {
                        let nextIndex = cleanedText.index(cleanedText.startIndex, offsetBy: i + 1)
                        let nextChar = cleanedText[nextIndex]
                        if nextChar.isWhitespace {
                            if i + 2 < cleanedText.count {
                                let nextNextIndex = cleanedText.index(cleanedText.startIndex, offsetBy: i + 2)
                                if cleanedText[nextNextIndex].isUppercase {
                                    isSentenceEnd = true
                                }
                            } else {
                                isSentenceEnd = true
                            }
                        }
                    }
                    
                    if isSentenceEnd {
                        sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                        currentSentence = ""
                    }
                }
                i += 1
            }
            if !currentSentence.isEmpty {
                sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            // Form summary from up to 3 sentences
            let maxSentences = 3
            var summary = ""
            for (index, sentence) in sentences.filter({ !$0.isEmpty }).enumerated() {
                if index >= maxSentences {
                    break
                }
                let sentenceWithDot = sentence.last == "." ? sentence : sentence + "."
                summary += (summary.isEmpty ? "" : " ") + sentenceWithDot
            }
            
            summary = summary.trimmingCharacters(in: .whitespaces)
            
            await MainActor.run {
                wikipediaSummary = summary.isEmpty ? NSLocalizedString("Информация недоступна", comment: "") : summary
            }
        } catch {
            print(NSLocalizedString("Ошибка загрузки данных с Википедии", comment: "") + ": \(error)")
            await MainActor.run {
                wikipediaSummary = NSLocalizedString("Информация недоступна", comment: "")
            }
        }
    }
    
    /// Maps weather condition to corresponding emoji
    private func weatherEmoji(_ condition: String?) -> String {
        guard let condition = condition?.lowercased() else { return "" }
        switch condition {
        case "sunny": return "☀️"
        case "clear": return "🌙"
        case "partly cloudy": return "⛅"
        case "cloudy": return "☁️"
        case "overcast": return "🌥️"
        case "mist": return "🌫️"
        case "fog": return "🌁"
        case "freezing fog": return "❄️"
        case "patchy rain possible": return "🌦️"
        case "light rain", "moderate rain", "heavy rain": return "🌧️"
        case "light rain shower": return "🚿"
        case "moderate or heavy rain shower", "torrential rain shower": return "🌧️"
        case "patchy light drizzle": return "💧"
        case "light drizzle": return "💦"
        case "freezing drizzle": return "🥶"
        case "heavy freezing drizzle": return "❄️"
        case "patchy light rain": return "🌦️"
        case "patchy snow possible": return "🌨️"
        case "light snow", "moderate snow", "heavy snow": return "❄️"
        case "light snow showers": return "🌨️"
        case "moderate or heavy snow showers": return "🌨️"
        case "patchy light snow": return "🌨️"
        case "ice pellets": return "🧊"
        case "light sleet", "moderate or heavy sleet", "patchy sleet possible": return "🌧️"
        case "thundery outbreaks possible": return "⚡"
        case "patchy light rain with thunder": return "⛈️"
        case "moderate or heavy rain with thunder": return "⛈️"
        case "patchy light snow with thunder": return "❄️"
        case "moderate or heavy snow with thunder": return "❄️"
        case "blowing snow": return "🌬️"
        case "blizzard": return "❄️"
        case "haze": return "🌫️"
        default: return ""
        }
    }
}

struct TagViewItem: Hashable, Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let currencyCode: String?
    let capitalName: String?
    
    init(title: String, icon: String, currencyCode: String? = nil, capitalName: String? = nil) {
        self.title = title
        self.icon = icon
        self.currencyCode = currencyCode
        self.capitalName = capitalName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TagViewItem, rhs: TagViewItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension Notification.Name {
    static let didTapCurrencyChip = Notification.Name("didTapCurrencyChip")
    static let didTapCapitalChip = Notification.Name("didTapCapitalChip")
}

struct UnsplashPhotoResponse: Codable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable {
    let urls: PhotoURLs
    
    struct PhotoURLs: Codable {
        let regular: String
    }
}

struct WeatherData: Codable {
    let temperature: Double
    let condition: String?
    
    enum CodingKeys: String, CodingKey {
        case temperature = "temp_c"
        case condition
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = try container.decode(Double.self, forKey: .temperature)
        if let conditionContainer = try? container.nestedContainer(keyedBy: ConditionCodingKeys.self, forKey: .condition) {
            condition = try conditionContainer.decode(String.self, forKey: .text)
        } else {
            condition = nil
        }
    }
    
    enum ConditionCodingKeys: String, CodingKey {
        case text
    }
}

struct WeatherAPIResponse: Codable {
    let current: WeatherData
}

struct WikipediaResponse: Codable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Codable {
    let pages: [String: WikipediaPage]
}

struct WikipediaPage: Codable {
    let extract: String?
}
