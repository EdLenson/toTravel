//  CountriesManager.swift
//  toTravel
//
//  Created by Ed on 3/26/25.
//

import Foundation
import Network

class CountriesManager: ObservableObject {
    static let shared = CountriesManager()
    
    private let cacheKey = "cachedCountries"
    @Published private var countryCodes: [String: String] = [:]
    private let fileManager = FileManager.default
    private let cacheFileURL: URL
    @Published private var countryAccessData: [String: [CountryAccess]] = [:]
    
    var countries: [String] {
        Array(countryCodes.values).sorted()
    }
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheFileURL = cachesDirectory.appendingPathComponent("countryAccessData.json")
        
        loadCachedCountries()
        loadCachedCountryAccessData()
        
        if countryCodes.isEmpty {
            fetchCountries()
        } else {
            print("Загружено \(countryCodes.count) стран из кеша")
        }
        
        setupBackgroundUpdates()
    }
    
    // MARK: - Управление списком стран
    
    func getCode(for country: String) -> String? {
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        if let code = countryCodes.first(where: { $0.value == trimmedCountry })?.key {
            return code
        } else {
            print("Код не найден для страны: \(trimmedCountry). Доступные страны: \(countries)")
            return nil
        }
    }
    
    func getName(forCode code: String) -> String {
        let upperCode = code.uppercased()
        return countryCodes[upperCode] ?? code
    }
    
    private func fetchCountries() {
        guard let url = URL(string: "https://flagcdn.com/ru/codes.json") else {
            print("Неверный URL для codes.json")
            return
        }
        
        let sovereignCountryCodes = Set([
            "AF", "AL", "DZ", "AD", "AO", "AG", "AR", "AM", "AU", "AT", "AZ", "BS", "BH", "BD", "BB",
            "BY", "BE", "BZ", "BJ", "BT", "BO", "BA", "BW", "BR", "BN", "BG", "BF", "BI", "KH", "CM",
            "CA", "CV", "CF", "TD", "CL", "CN", "CO", "KM", "CG", "CD", "CR", "CI", "HR", "CU", "CY",
            "CZ", "DK", "DJ", "DM", "DO", "EC", "EG", "SV", "GQ", "ER", "EE", "SZ", "ET", "FJ", "FI",
            "FR", "GA", "GM", "GE", "DE", "GH", "GR", "GD", "GT", "GN", "GW", "GY", "HT", "HN", "HU",
            "IS", "IN", "ID", "IR", "IQ", "IE", "IL", "IT", "JM", "JP", "JO", "KZ", "KE", "KI", "KP",
            "KR", "KW", "KG", "LA", "LV", "LB", "LS", "LR", "LY", "LI", "LT", "LU", "MG", "MW", "MY",
            "MV", "ML", "MT", "MH", "MR", "MU", "MX", "FM", "MD", "MC", "MN", "ME", "MA", "MZ", "MM",
            "NA", "NR", "NP", "NL", "NZ", "NI", "NE", "NG", "NO", "OM", "PK", "PW", "PA", "PG", "PY",
            "PE", "PH", "PL", "PT", "QA", "RO", "RU", "RW", "KN", "LC", "VC", "WS", "SM", "ST", "SA",
            "SN", "RS", "SC", "SL", "SG", "SK", "SI", "SB", "SO", "ZA", "SS", "ES", "LK", "SD", "SR",
            "SE", "CH", "SY", "TJ", "TH", "TL", "TG", "TO", "TT", "TN", "TR", "TM", "TV", "UG", "UA",
            "AE", "GB", "US", "UY", "UZ", "VU", "VE", "VN", "YE", "ZM", "ZW", "TZ", "HK", "MO", "MK",
            "TW", "PS", "XK"
        ])
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки codes.json: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Нет данных от codes.json")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([String: String].self, from: data)
                let filtered = Dictionary(uniqueKeysWithValues: decoded.filter {
                    !$0.key.contains("-") && sovereignCountryCodes.contains($0.key.uppercased())
                }.map { ($0.key.uppercased(), $0.value) })
                DispatchQueue.main.async {
                    self.countryCodes = filtered
                    self.saveCountriesToCache()
                    print("Загружено и сохранено \(filtered.count) суверенных стран")
                }
            } catch {
                print("Ошибка декодирования codes.json: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func saveCountriesToCache() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(countryCodes) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadCachedCountries() {
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: cachedData) {
            countryCodes = decoded
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
