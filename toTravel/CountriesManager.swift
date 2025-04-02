import Foundation
import Network

class CountriesManager: ObservableObject {
    static let shared = CountriesManager()
    
    private let cacheKey = "cachedCountries"
    @Published private var countries: [Country] = []
    private let fileManager = FileManager.default
    private let cacheFileURL: URL
    @Published private var countryAccessData: [String: [CountryAccess]] = [:]
    
    var countryNames: [String] {
        countries.filter { $0.isIndependent }.map { $0.name }.sorted()
    }
    
    struct Country: Codable, Identifiable {
        let id = UUID()
        let name: String
        let code: String
        let flagURL: String
        let isIndependent: Bool
        
        enum CodingKeys: String, CodingKey {
            case name, code, flagURL, isIndependent
        }
    }
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheFileURL = cachesDirectory.appendingPathComponent("countryAccessData.json")
        
        loadCachedCountries()
        loadCachedCountryAccessData()
        
        if countries.isEmpty {
            fetchCountries()
        } else {
            print("Загружено \(countries.count) стран из кеша")
        }
        
        setupBackgroundUpdates()
    }
    
    // MARK: - Управление списком стран
    
    func getCode(for country: String) -> String? {
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        if let country = countries.first(where: { $0.name == trimmedCountry }) {
            return country.code
        } else {
            print("Код не найден для страны: \(trimmedCountry). Доступные страны: \(countryNames)")
            return nil
        }
    }
    
    func getName(forCode code: String) -> String {
        let upperCode = code.uppercased()
        return countries.first(where: { $0.code == upperCode })?.name ?? code
    }
    
    // Метод для получения URL флага по названию страны (оставляем для совместимости)
    func getFlagURL(for country: String) -> URL? {
        if let country = countries.first(where: { $0.name == country }) {
            return URL(string: country.flagURL)
        }
        return nil
    }
    
    // Метод для получения URL флага по коду страны
    func getFlagURL(forCode code: String) -> URL? {
        let upperCode = code.uppercased()
        if let country = countries.first(where: { $0.code == upperCode }) {
            return URL(string: country.flagURL)
        }
        return nil
    }
    
    private func fetchCountries() {
        guard let url = URL(string: "https://restcountries.com/v3.1/all") else {
            print("Неверный URL для restcountries")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки restcountries: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Нет данных от restcountries")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let allCountries = try decoder.decode([RestCountry].self, from: data)
                
                let locale = Locale.current.language.languageCode?.identifier ?? "ru"
                let fetchedCountries = allCountries.map { restCountry in
                    let name = locale == "ru" ? (restCountry.translations["rus"]?.common ?? restCountry.name.common) : restCountry.name.common
                    return Country(
                        name: name,
                        code: restCountry.cca2.uppercased(),
                        flagURL: restCountry.flags.png,
                        isIndependent: restCountry.independent ?? false
                    )
                }
                
                DispatchQueue.main.async {
                    self.countries = fetchedCountries
                    self.saveCountriesToCache()
                    print("Загружено и сохранено \(fetchedCountries.count) стран")
                }
            } catch {
                print("Ошибка декодирования restcountries: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private struct RestCountry: Decodable {
        let name: Name
        let cca2: String
        let independent: Bool?
        let translations: [String: Translation]
        let flags: Flags
        
        struct Name: Decodable {
            let common: String
        }
        
        struct Translation: Decodable {
            let common: String
        }
        
        struct Flags: Decodable {
            let png: String
        }
    }
    
    private func saveCountriesToCache() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(countries) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadCachedCountries() {
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([Country].self, from: cachedData) {
            countries = decoded
        }
    }
    
    // MARK: - Управление данными о визах
    
    func getCountryAccessData() -> [String: [CountryAccess]] {
        return countryAccessData
    }
    
    private func saveCountryAccessData(_ data: [String: [CountryAccess]]) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: cacheFileURL)
        print("CountryAccessData сохранены на диск: \(cacheFileURL.path)")
    }
    
    private func loadCachedCountryAccessData() {
        guard fileManager.fileExists(atPath: cacheFileURL.path) else {
            print("Кэшированный файл countryAccessData не найден")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            let data = try decoder.decode([String: [CountryAccess]].self, from: jsonData)
            self.countryAccessData = data
            print("CountryAccessData загружены с диска")
        } catch {
            print("Ошибка загрузки кэшированных данных CountryAccessData: \(error.localizedDescription)")
        }
    }
    
    private func isCountryAccessDataDifferent(_ newData: [String: [CountryAccess]], from oldData: [String: [CountryAccess]]) -> Bool {
        return newData != oldData
    }
    
    // MARK: - Фоновое обновление
    
    private func setupBackgroundUpdates() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.fetchCountries()
                
                Task {
                    do {
                        let newData = try await CSVParser.fetchCountryAccessData()
                        if self.isCountryAccessDataDifferent(newData, from: self.countryAccessData) {
                            await MainActor.run {
                                self.countryAccessData = newData
                            }
                            try self.saveCountryAccessData(newData)
                            print("CountryAccessData обновлены в фоне")
                        }
                    } catch {
                        print("Ошибка фонового обновления CountryAccessData: \(error.localizedDescription)")
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
}
